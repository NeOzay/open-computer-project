local fs = require("filesystem")
local serialization = require("serialization")
local computer = require("computer")
local inspect = require("inspect")
local JSON = require("dkjson")
local inet = require("internet")

print("load github")
local function freeMemory()
  if computer.freeMemory() < 50000 then
    print("Low memory, collecting garbage")
    for _ = 1, 20 do os.sleep(0) end
  end
end

-- Build a github API url, with authorization headers.
---@param path string
---@param auth Auth
---@return response,table
local function getAPI(path, auth)
  freeMemory()
  local url = ('https://api.github.com/%s'):format(path)
  local headers
  if auth and auth.type == 'oauth' then
    headers = { ['Authorization'] = ('token %s'):format(auth.token) }
  end

  --print(url)
  local handle = inet.request(url, nil, headers)
  local json = {}
  for chunk in handle do
    table.insert(json, chunk)
  end
  local data = JSON.decode(table.concat(json)) ---@cast data table
  handle.finishConnect()
  local rawReponce = { handle.response() }
  ---@class response
  ---@field code number
  ---@field message string
  ---@field headers table
  local response = {
    code = rawReponce[1],
    message = rawReponce[2],
    headers = rawReponce[3]
  }
  return response, data
end

---@param s string
local function encodeURI(s)
  return s:gsub(' ', '%%20')
end

---@param blob Blob
---@param sha string branch or tag
---@param path string
local function downloadFile(blob, sha, path)
  freeMemory()
  local auth = blob.repo.auth
  local headers
  if auth and auth.type == 'oauth' then
    headers = { ['Authorization'] = ('token %s'):format(auth.token) }
  end
  local url = ('https://raw.githubusercontent.com/%s/%s/%s/%s'):format(blob.repo.user, blob.repo.name, sha,
    encodeURI(blob.fullpath))
  --print(url)
  local handle = inet.request(url, nil, headers)
  if handle then
    local h, reason = io.open(path, 'w')
    if h then
      for chunk in handle do
        h:write(chunk)
        freeMemory()
      end
      h:close()
    else
      error(reason)
    end
  else
    error('Could not get file from ' .. url)
  end
end

-- A class for authorization
local authFile = '/home/.github-auth'
---@param data table<string, Auth>
local function save_auth(data)
  local f, reason = io.open(authFile, 'w')
  if f then
    f:write(serialization.serialize(data))
    f:close()
  else
    error(reason)
  end
end

local function get_auth_list()
  ---@type table<string, Auth>
  local authTable = {}
  if fs.exists(authFile) then
    local f, reason = io.open(authFile, 'r')
    if f then
      authTable = serialization.unserialize(f:read())
      f:close()
    else
      error(reason)
    end
  end
  return authTable
end

local auth_list = get_auth_list()

---@class Auth
---@field type string
---@field user string
---@field token string
local Auth = {}
Auth.__index = Auth

---@param type string
---@param user string
---@param token string
---@return Auth
function Auth.new(type, user, token)
  return setmetatable({ type = type, user = user, token = token }, Auth)
end

---@param user string
---@return Auth?
function Auth.get(user)
  local auth = auth_list[user]
  if auth then
    return Auth.new(auth.type, auth.user, auth.token)
  end
end

function Auth:save()
  auth_list[self.user] = self
  save_auth(auth_list)
end

function Auth:delete()
  auth_list[self.user] = nil
  save_auth(auth_list)
end

function Auth:checkToken()
  local status, _ = getAPI('user', self)
  return status.code == 200
end

-- A class for a blob (aka a file)
---@class Blob
---@field path string
---@field repo repo
---@field sha string
---@field parent Tree
---@field size number
---@field fullpath string
local Blob = {}
Blob.__index = Blob

---@param repo repo
---@param sha string
---@param fullpath string
---@return  Blob
function Blob.new(repo, sha, fullpath)
  return setmetatable({ repo = repo, sha = sha, fullpath = fullpath, path = fs.name(fullpath) }, Blob)
end

---@param relatif? Tree
function Blob:relatifPath(relatif)
  if self.parent and self ~= relatif then
    return fs.concat(self.parent:relatifPath(relatif), self.path)
  elseif self == relatif then
    return ""
  else
    return self.path
  end
end

---@param subdir string
---@param file string
local function include(subdir, file)
  local cut_file = fs.segments(file)
  for i, s in ipairs(fs.segments(subdir)) do
    if cut_file[i] and cut_file[i] ~= s then
      return false
    elseif not cut_file[i] then
      return true
    end
  end
  return true
end

-- A class for a tree (aka a folder)
---@class Tree
---@field repo repo
---@field sha string
---@field path string
---@field fullpath string
---@field parent Tree
---@field size number
---@field contents (Tree|Blob)[]
local Tree = {}
Tree.__index = Tree

---@param repo repo
---@param sha string
---@param fullpath? string
---@param subdir? string
---@return Tree
function Tree.new(repo, sha, fullpath, subdir)
  local url = ('repos/%s/%s/git/trees/%s'):format(repo.user, repo.name, sha)
  local status, data = getAPI(url, repo.auth)
  if status.code ~= 200 or not data then
    if status.message then
      io.stderr:write(status.message.."\n")
    end
    io.stderr:write("code: "..(status.code or "no code"))
    io.stderr:write("\n")
    error('Could not get github API from ' .. url)
  end

  if data.tree then
    local tree = setmetatable({
      repo = repo,
      sha = data.sha,
      fullpath = fullpath or '',
      path = fs.name(fullpath or '') or '',
      size = 0,
      contents = {}
    }, Tree)

    for _, childdata in ipairs(data.tree) do
      local childFullPath = fs.concat(tree.fullpath, childdata.path)
      if not subdir or (include(subdir, childFullPath)) then
        ---@type Tree|Blob
        local child
        if childdata.type == 'blob' then
          child = Blob.new(repo, childdata.sha, childFullPath)
          child.size = childdata.size
        elseif childdata.type == 'tree' then
          child = Tree.new(repo, childdata.sha, childFullPath, subdir)
        else
          error("uh oh " .. JSON.encode(childdata))
        end

        tree.size = tree.size + child.size
        child.parent = tree
        table.insert(tree.contents, child)
      end
    end
    return tree
  else
    error("uh oh: " .. JSON.encode(data))
  end
end

---@param t Tree
---@param level number
local function walkTree(t, level)
  for _, item in ipairs(t.contents) do
    coroutine.yield(item, level)
    if getmetatable(item) == Tree then ---@cast item Tree
      walkTree(item, level + 1)
    end
  end
end

---@return Tree
function Tree:getRoot()
  if self.parent then
    return self.parent:getRoot()
  else
    return self
  end
end

---@return fun():Tree|Blob,number
function Tree:iter()
  return coroutine.wrap(function()
    walkTree(self, 0)
  end)
end

---@param dest string
---@param onProgress? fun(item:Blob|Tree, number:number)
function Tree:cloneTo(dest, onProgress)
  if not fs.exists(dest) then
    fs.makeDirectory(dest)
  elseif not fs.isDirectory(dest) then
    return error("Destination is a file!")
  end
  local root_tree = self:getRoot()
  for item, level in self:iter() do
    local path = fs.concat(dest, item:relatifPath(self))
    if getmetatable(item) == Tree then
      fs.makeDirectory(path)
    elseif getmetatable(item) == Blob then ---@cast item Blob
      downloadFile(item, root_tree.sha, path)
    end
    if onProgress then onProgress(item, level) end
  end
end

--Tree.fullPath = Blob.fullPath
Tree.relatifPath = Blob.relatifPath

-- A class for a repo
---@type table<repo,{trees:table<string,Tree>}>
local __repoPriv = setmetatable({}, { mode = 'k' })
---@class repo
---@field user string
---@field name string
---@field auth Auth
---@field sha string
local Repository = {}

Repository.__index = Repository

---@param url string
---@param auth Auth
local function releaseFromURL(url, auth)
  local status, data = getAPI(url, auth)
  if status.code ~= 200 or not data then
    if status.message then
      io.stderr:write(status.message.."\n")
    end
    io.stderr:write("code: "..(status.code or "no code"))
    io.stderr:write("\n")
    error('Could not get release github API from ' .. url)
  end
  -- format is described at https://developer.github.com/v3/repos/releases/
  return data["tag_name"] or data["default_branch"]
end

---@param owner string
---@param repo string
---@param opt {auth?:Auth, tag?:string, branch?:string, latestRelease?:boolean, subdir:string}
---@return repo
function Repository.new(owner, repo, opt)
  if opt.auth then
    if not opt.auth:checkToken() then
      error("token invalid")
    end
  end

  local sha
  if opt.latestRelease then
    sha = releaseFromURL(('repos/%s/%s/releases/latest'):format(owner, repo), opt.auth)
  elseif opt.tag then
    sha = releaseFromURL(('repos/%s/%s/releases/tags/%s'):format(owner, repo, opt.tag), opt.auth)
  elseif opt.branch then
    sha = opt.branch
  else
    sha = releaseFromURL(('repos/%s/%s'):format(owner, repo), opt.auth)
  end
  if not sha then
    error("no sha found")
  end
  local r = setmetatable({ user = owner, name = repo, auth = opt.auth, sha = sha }, Repository)
  __repoPriv[r] = { trees = {} }
  if not __repoPriv[r].trees[sha] then
    __repoPriv[r].trees[sha] = Tree.new(r, sha, nil, opt.subdir)
  end
  return r
end

function Repository:getRepoSize()
  return __repoPriv[self].trees[self.sha].size
end

function Repository:changeBranch(sha)
  self.sha = sha
  if not __repoPriv[self].trees[sha] then
    __repoPriv[self].trees[sha] = Tree.new(self, sha)
  end
end

---@param dest string
---@param onProgress? fun(item:Blob|Tree, number:number)
function Repository:cloneTo(dest, onProgress)
  local tree = __repoPriv[self].trees[self.sha]
  tree:cloneTo(dest, onProgress)
end

---@param dest string
---@param subdir string
---@param onProgress? fun(item:Blob|Tree, number:number, tree:Tree)
function Repository:cloneTreeTo(dest, subdir, onProgress)
  local subdir_parts = fs.segments(subdir)
  local tree = __repoPriv[self].trees[self.sha] ---@type Tree
  local _break
  for _, treeName in ipairs(subdir_parts) do
    _break = false
    for _, item in ipairs(tree.contents) do
      if getmetatable(item) == Tree and item.path == treeName then ---@cast item Tree
        tree = item
        _break = true
        break
      end
    end
    if not _break then
      ---@diagnostic disable-next-line: cast-local-type
      tree = nil
      break
    end
  end

  if tree then
    tree:cloneTo(dest, onProgress and function (item, number)
      return onProgress(item, number, tree)
    end)
  else
    error("no tree found")
  end
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
github.repo = Repository.new
return github
