local fs = require("filesystem")
local serialization = require("serialization")
local computer = require("computer")

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
---@param token token
---@return response,table
local function getAPI(path, token)
  freeMemory()
  local url = ('https://api.github.com/%s'):format(path)
  local headers
  if token and token.type == 'oauth' then
    headers = { ['Authorization'] = ('token %s'):format(token.token) }
  end

  --print(url)
  local handle = inet.request(url, nil, headers)
  local rawJson = {}
  for chunk in handle do
    table.insert(rawJson, chunk)
  end
  local data = JSON.decode(table.concat(rawJson)) ---@cast data table
  handle.finishConnect()
  local c, m, h = handle.response()
  return { code = c, message = m, headers = h }, data
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
  local token = blob.repo.token
  local headers
  if token and token.type == 'oauth' then
    headers = { ['Authorization'] = ('token %s'):format(token.token) }
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

---@return table<string, token>
local function load_token_cache()
  if not fs.exists(authFile) then
    return {}
  end

  local authTable
  local f, reason = io.open(authFile, 'r')
  if f then
    authTable = serialization.unserialize(f:read())
    f:close()
  else
    error(reason)
  end

  return authTable
end

---@class token
---@field token string
---@field user string
---@field type string

---@class Auth
local Auth = {}
Auth.__index = Auth
Auth._cache = load_token_cache()

function Auth.save_to_file()
  local f, reason = io.open(authFile, 'w')
  if f then
    f:write(serialization.serialize(Auth._cache))
    f:close()
  else
    error(reason)
  end
end

---@param user string
---@param token string
---@return token
function Auth.new_token(user, token)
  return { type = "oauth", user = user, token = token }
end

---@param user string
---@return token?
function Auth.get(user)
  return Auth._cache[user]
end

---@param user string
---@return boolean
function Auth.has(user)
  return Auth._cache[user] ~= nil
end

---@param user string
---@param token string
---@return token
function Auth.add(user, token)
  Auth._cache[user] = Auth.new_token(user, token)
  Auth.save_to_file()
  return Auth._cache[user]
end

function Auth.delete(user)
  Auth._cache[user] = nil
  Auth.save_to_file()
end

---@param token token
---@return boolean
function Auth.checkToken(token)
  local status, _ = getAPI('user', token)
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

---@param tree? Tree
function Blob:relatifTo(tree)
  if self.parent and self ~= tree then
    return fs.concat(self.parent:relatifTo(tree), self.path)
  elseif self == tree then
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

---@param path string
---@param excluded_types table<string, boolean>
---@return boolean
function isNotExclude(path, excluded_types)
  for file_type in pairs(excluded_types) do
    if string.find(path, file_type .. "$") then
      return false
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
---@field numberofchild number
---@field blobsCount number
local Tree = {}
Tree.__index = Tree

---@param repo repo
---@param sha string
---@param fullpath? string
---@param subdir? string
---@return Tree
function Tree.new(repo, sha, fullpath, subdir)
  local url = ('repos/%s/%s/git/trees/%s'):format(repo.user, repo.name, sha)
  local status, data = getAPI(url, repo.token)
  if status.code ~= 200 or not data then
    if status.message then
      io.stderr:write(status.message .. "\n")
    end
    io.stderr:write("code: " .. (status.code or "no code"))
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
      numberofchild = 0,
      blobsCount = 0,
      contents = {}
    }, Tree)

    for _, childdata in ipairs(data.tree) do
      local childFullPath = fs.concat(tree.fullpath, childdata.path)
      if (not subdir or include(subdir, childFullPath)) and  isNotExclude(childdata.path, repo.excluded) then
        ---@type Tree|Blob
        local child
        if childdata.type == 'blob' then
          child = Blob.new(repo, childdata.sha, childFullPath)
          child.size = childdata.size
          tree.blobsCount = tree.blobsCount + 1
        elseif childdata.type == 'tree' then
          child = Tree.new(repo, childdata.sha, childFullPath, subdir)
          tree.numberofchild = tree.numberofchild + child.numberofchild
          tree.blobsCount = tree.blobsCount + child.blobsCount
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
    local path = fs.concat(dest, item:relatifTo(self))
    if getmetatable(item) == Tree then
      fs.makeDirectory(path)
    elseif getmetatable(item) == Blob then ---@cast item Blob
      downloadFile(item, root_tree.sha, path)
    end
    if onProgress then onProgress(item, level) end
  end
end

--Tree.fullPath = Blob.fullPath
Tree.relatifTo = Blob.relatifTo

-- A class for a repo
---@type table<string, repo>
__repoPriv = {}
---@class repo
---@field user string
---@field name string
---@field token? token
---@field sha string
---@field subdir string
---@field excluded table<string, boolean>
---@field trees table<string,Tree>
local Repository = {}

Repository.__index = Repository

---@param url string
---@param token token
local function releaseFromURL(url, token)
  local status, data = getAPI(url, token)
  if status.code ~= 200 or not data then
    if status.message then
      io.stderr:write(status.message .. "\n")
    end
    io.stderr:write("code: " .. (status.code or "no code"))
    io.stderr:write("\n")
    error('Could not get release github API from ' .. url)
  end
  -- format is described at https://developer.github.com/v3/repos/releases/
  return data["tag_name"] or data["default_branch"]
end

local function same_table(t1, t2)
  for key in pairs(t1) do
    if not t2[key] then
      return false
    end
  end
  for key in pairs(t2) do
    if not t1[key] then
      return false
    end
  end
  return true
end

---@param owner string
---@param repo string
---@param opt {token?:token, tag?:string, branch?:string, latestRelease?:boolean, subdir?:string, excluded?:string[]}
---@return repo
function Repository.new(owner, repo, opt)
  if opt.token then
    if not Auth.checkToken(opt.token) then
      error("token invalid")
    end
  end

  local sha
  if opt.latestRelease then
    sha = releaseFromURL(('repos/%s/%s/releases/latest'):format(owner, repo), opt.token)
  elseif opt.tag then
    sha = releaseFromURL(('repos/%s/%s/releases/tags/%s'):format(owner, repo, opt.tag), opt.token)
  elseif opt.branch then
    sha = opt.branch
  else
    sha = releaseFromURL(('repos/%s/%s'):format(owner, repo), opt.token)
  end
  if not sha then
    error("no sha found")
  end

  local r
  if not __repoPriv[owner .. "/" .. repo] then
    r = setmetatable(
    { user = owner, name = repo, token = opt.token, sha = sha, excluded = opt.excluded or {}, trees = {}, subdir = opt.subdir }, Repository)
    __repoPriv[owner .. "/" .. repo] = r
  else
    r = __repoPriv[owner .. "/" .. repo]
    r.sha = sha
    r.token = opt.token or r.token
 
  end

  if not r.trees[sha] or r.subdir ~= opt.subdir or not same_table(r.excluded, opt.excluded) then
    r.subdir = opt.subdir
    r.excluded = opt.excluded
    r.trees[sha] = Tree.new(r, sha, nil, opt.subdir)
  end
  return r
end

function Repository:getRepoSize()
  return self.trees[self.sha].size
end

function Repository:changeBranch(sha)
  self.sha = sha
  if not self.trees[sha] then
    self.trees[sha] = Tree.new(self, sha)
  end
end

function Repository:changeToLatestRelease()
  local sha = releaseFromURL(('repos/%s/%s/releases/latest'):format(self.user, self.name), self.token)
  self.sha = sha
  if not self.trees[sha] then
    self.trees[sha] = Tree.new(self, sha)
  end
end

function Repository:changeTag(tag)
  local sha = releaseFromURL(('repos/%s/%s/releases/tags/%s'):format(self.user, self.name, tag), self.token)
  self.sha = sha
  if not self.trees[sha] then
    self.trees[sha] = Tree.new(self, sha)
  end
end

---@param dest string
---@param onProgress? fun(item:Blob|Tree, number:number, roottree:Tree)
---@param subdir? string
function Repository:cloneTo(dest, onProgress, subdir)
  local tree = self.trees[self.sha] ---@type (Tree|Blob)?
  if not tree then
    error("not tree found for this sha: "..self.sha)
  end

  if subdir then
    local tmp = tree
    local subdir_parts = fs.segments(subdir)
    local match
    for _, tree_part in ipairs(subdir_parts) do
      match = false
      for _, item in ipairs(tmp.contents) do
        if item.path == tree_part then
          tmp = item
          match = true
          break
        end
      end
      if not match then
        error("no tree found")
      end
    end
    tree = tmp
  end
  if getmetatable(tree) == Tree then ---@cast tree Tree
    tree:cloneTo(dest, onProgress and function(item, number)
      return onProgress(item, number, tree)
    end)
  elseif getmetatable(tree) == Blob then ---@cast tree Blob
    onProgress(tree, 1, tree.parent)
    downloadFile(tree, self.sha, tree.path)
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
