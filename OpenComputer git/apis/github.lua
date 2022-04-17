local component = require("component")
local fs = require("filesystem")
local serialization = require("serialization")
local internet = require("internet")

local JSON = require("dkjson")
local internetCard = component.internet

local _


---@param handle any
local function readAll(handle)
    ---@type string
    local chunk
    ---@type string[]
    local data = {}
    while true do
        chunk = handle.read(math.huge)

        if chunk then
            table.insert(data,chunk)
        else
            break
        end
    end
    return table.concat(data)
end

-- Build a github API url, with authorization headers.
---@param path string
---@param auth auth
---@return response,table
local function getAPI(path, auth)
    local url = ('https://api.github.com/%s'):format(path)
    local headers
    if auth and auth.type == 'oauth' then
        headers = { ['Authorization'] = ('token %s'):format(auth.token) }
    end

    local handle = internetCard.request(url, _,headers)

    ---@type table
    local data = JSON.decode(readAll(handle))
    handle.close()

    local rawReponce = { handle.response() }
    ---@class response
    ---@field code number
    ---@field message string
    ---@field headers table
    local reponse = { code = rawReponce[1],
                      message = rawReponce[2],
                      headers = rawReponce[3] }
    return reponse, data
end

---@param s string
local function encodeURI(s)
    return s:gsub(' ', '%%20')
end

---@param blob blob
---@param path string
local function downloadFile(blob, sha, path)
    local auth = blob.repo.auth
    local headers
    if auth and auth.type == 'oauth' then
        headers = { ['Authorization'] = ('token %s'):format(auth.token) }
    end
    local url = ('https://raw.githubusercontent.com/%s/%s/%s/%s'):format(blob.repo.user, blob.repo.name, sha, encodeURI(blob:fullPath()))
    local handle = internetCard.request(url,_ , headers)

    local h = io.open(path, 'w')
    h:write(readAll(handle))
    h:close()
    handle.close()
end

-- A class for authorization
local authFile = '/home/.github-auth'
---@param data table<string,userData>
local function writeAuth(data)
    local f = io.open(authFile, 'w')
    f:write(serialization.serialize(data))
    f:close()
end
local function getAuthTable()
    ---@class userData
    ---@field type string
    ---@field token string
    ---@field user string

    ---@type table<string,userData>
    local authTable = {}
    if fs.exists(authFile) then
        local f = io.open(authFile, 'r')
        authTable = serialization.unserialize(f:read())
        f:close()
    end
    return authTable
end

---@class auth
---@field type string
---@field user string
---@field token string
local Auth = {}
Auth.__index = Auth

---@param type string
---@param user string
---@param token string
---@return auth
function Auth.new(type, user, token)
    return setmetatable({ type = type, user = user, token = token }, Auth)
end

---@param user string
function Auth.get(user)
    local authTable = getAuthTable()
    local auth = authTable[user]
    if auth then
        return Auth.new(auth.type, auth.user, auth.token)
    end

end

function Auth:save()
    local authTable = getAuthTable()
    authTable[self.user] = self
    writeAuth(authTable)
end

---@param user string
function Auth.delete(user)
    local authTable = getAuthTable()
    authTable[user] = nil
    writeAuth(authTable)
end

function Auth:checkToken()
    local status, _ = getAPI('user', self)
	return status.code == 200
end

-- A class for a blob (aka a file)
---@class blob
---@field path string
---@field repo repo
---@field sha string
---@field parent tree
local Blob = {}
Blob.__index = Blob

---@param repo table
---@param sha string
---@param path string
---@return  blob
function Blob.new(repo, sha, path)
    return setmetatable({ repo = repo, sha = sha, path = path }, Blob)
end

---@return string
function Blob:fullPath()
    ---@type string
    local fullPath
    if self.parent then
        fullPath = fs.concat(self.parent:fullPath(), self.path)
        function self:fullPath() return fullPath end
        return fullPath
    else
        return self.path
    end
end

-- A class for a tree (aka a folder)
---@class tree
---@field repo repo
---@field sha string
---@field path string
---@field parent tree
---@field size number
---@field contents tree[]|blob[]
local Tree = {}
Tree.__index = Tree

---@param repo repo
---@param sha string
---@param path string
---@return tree
---@overload fun(repo:repo,sha:string):tree
function Tree.new(repo, sha, path)
    local url = ('repos/%s/%s/git/trees/%s'):format(repo.user, repo.name, sha)
    local status, data = getAPI(url, repo.auth)
    if not status then
        error('Could not get github API from ' .. url)
    end

    if data.tree then

        ---@type tree
        local tree = setmetatable({
            repo = repo, sha = data.sha,
            path = path or '', size = 0,
            contents = {}
        }, Tree)

        for _, childdata in ipairs(data.tree) do
            childdata.fullPath = fs.concat(tree:fullPath(), childdata.path)
            ---@type tree|blob
            local child
            if childdata.type == 'blob' then
                child = Blob.new(repo, childdata.sha, childdata.path)
                child.size = childdata.size
            elseif childdata.type == 'tree' then
                child = Tree.new(repo, childdata.sha, childdata.path)
            else
                error("uh oh", JSON.encode(childdata))
                --child = childdata
            end

            tree.size = tree.size + child.size
            child.parent = tree
            table.insert(tree.contents, child)

        end
        return tree
    else
        error("uh oh", JSON.encode(data))
    end
end

---@param t tree
---@param level number
local function walkTree(t, level)
    for _, item in ipairs(t.contents) do
        coroutine.yield(item, level)
        if getmetatable(item) == Tree then
            walkTree(item, level + 1)
        end
    end
end

---@return fun():tree|blob,number
function Tree:iter()
    return coroutine.wrap(function()
        walkTree(self, 0)
    end)
end

---@param dest string
---@param onProgress fun(item:blob|tree,number:number)
---@overload fun(dest:string)
function Tree:cloneTo(dest, onProgress)
    if not fs.exists(dest) then
        fs.makeDirectory(dest)
    elseif not fs.isDirectory(dest) then
        return error("Destination is a file!")
    end

    for item,level in self:iter() do
        local gitpath = item:fullPath()
        local path = fs.concat(dest, gitpath)
        if getmetatable(item) == Tree then
            fs.makeDirectory(path)
        elseif getmetatable(item) == Blob then
            downloadFile(--[[---@not tree]] item, self.sha, path)
        end
        if onProgress then onProgress(item,level) end
    end
end
Tree.fullPath = Blob.fullPath

-- A class for a release
---@class release
---@field repo repo
---@field tag string
local Release = {}
Release.__index = Release

---@param repo repo
---@param tag string
---@return release
function Release.new(repo, tag)
    return setmetatable({ repo = repo, tag = tag }, Release)
end

function Release:tree()
    return self.repo:tree(self.tag)
end

-- A class for a repo
---@type table<repo,table<"trees",table<string,tree>>>
local __repoPriv = setmetatable({}, { mode = 'k' })
---@class repo
---@field user string
---@field name string
---@field auth auth
local Repository = {}

Repository.__index = Repository

---@param user string
---@param name string
---@param auth auth
---@return repo
---@overload fun(user:string,name:string):repo
function Repository.new(user, name, auth)
    if auth then
        auth:checkToken()
    end
    local r = setmetatable({ user = user, name = name, auth = auth }, Repository)
    __repoPriv[r] = { trees = {} }
    return r
end

---@param sha string
---@overload fun():tree
function Repository:tree(sha)
    sha = sha or "master"
    if not __repoPriv[self].trees[sha] then
        __repoPriv[self].trees[sha] = Tree.new(self, sha)
    end
    return __repoPriv[self].trees[sha]
end

---@param url string
---@param repo repo
local function releaseFromURL(url, repo)
    local status, data = getAPI(url, repo.auth)
    if not status then
        error('Could not get release github API from ' .. url)
    end
    -- format is described at https://developer.github.com/v3/repos/releases/
    return Release.new(repo, data["tag_name"])
end

function Repository:latestRelease()
    return releaseFromURL(('repos/%s/%s/releases/latest'):format(self.user, self.name), self)
end

---@param tag string
function Repository:releaseForTag(tag)
    return releaseFromURL(('repos/%s/%s/releases/tags/%s'):format(self.user, self.name, tag), self)
end

function Repository:__tostring()
    return ("Repo@%s/%s"):format(self.user, self.name)
end


-- Export members
local github = {}
github.Repository = Repository
github.Blob = Blob
github.Tree = Tree
github.Auth = Auth
github.Release = Release
github.repo = Repository.new
return github