local fs = require("filesystem")
local serialization = require("serialization")
local computer = require("computer")

local JSON = require("JSON")
local inet = require("internet")

local function freeMemory()
   if computer.freeMemory() < 50000 then
      print("Low memory, collecting garbage")
      for _ = 1, 20 do os.sleep(0) end
   end
end

-- Build a github API url, with authorization headers.
---@param path string
---@param token token
---@param headers? table<string, string>
---@return response,table
local function getAPI(path, token, headers)
   freeMemory()
   local url = path
   if not path:find("^https://") then
      url = ('https://api.github.com/%s'):format(path)
   end
   headers = headers or {}
   if token and token.type == 'oauth' then
      headers['Authorization'] = ('token %s'):format(token.token)
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

---@param repo repo
---@param path string
---@param dest string
---@return boolean success
---@return string? error
local function downloadFile(repo, path, dest)
   freeMemory()
   local token = repo.token
   local headers
   if token and token.type == 'oauth' then
      headers = { ['Authorization'] = ('token %s'):format(token.token) }
   end
   local url = ('https://raw.githubusercontent.com/%s/%s/%s/%s'):format(repo.user, repo.name, repo.sha, encodeURI(path))
   --print(url)
   local handle = inet.request(url, nil, headers)
   while not handle.finishConnect() do os.sleep(0.2) end
   if handle.response() ~= 200 then
      return false, 'Could not get file from ' .. url.. " code: " .. tostring(handle.response())
   end
   local h, reason = io.open(dest, 'w')
   if h then
      for chunk in handle do
         h:write(chunk)
         freeMemory()
      end
      h:close()
   else
      error(reason)
   end
   return true
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

---@param path string
---@param excluded_types table<string, boolean>
---@return boolean
local function isExclude(path, excluded_types)
   for file_type in pairs(excluded_types) do
      if string.find(path, file_type .. "$") then
         return true
      end
   end
   return false
end

---@class rawdata
---@field sha string
---@field path string
---@field type string|"tree"|"blob"
---@field size number
---@field url string
---@field mode string
---@field parent Tree

-- A class for a tree (aka a folder)
---@class Tree
---@field repo repo
---@field sha string
---@field path string
---@field name string
---@field parent? Tree
---@field size number
---@field blobs table<string, rawdata>
---@field trees table<string, rawdata>
---@field __trees table<string, Tree>
---@field blobsCount number
---@field treesCount number
local Tree = {}
Tree.__index = Tree

---@param repo repo
---@param rawdata string|rawdata -- sha or rawdata
---@param recursively? boolean
---@return Tree
function Tree.new(repo, rawdata, recursively)
   local sha
   local path
   local parent
   if type(rawdata) == "table" then
      sha = rawdata.sha
      path = rawdata.path
      parent = rawdata.parent
   else
      sha = rawdata
      path = ""
   end
   local url = ('repos/%s/%s/git/trees/%s'):format(repo.user, repo.name, sha)
   if recursively then
      url = url .. '?recursive=true'
   end
   local status, data = getAPI(url, repo.token)
   if status.code ~= 200 or not data then
      if status.message then
         io.stderr:write(status.message .. "\n")
      end
      io.stderr:write("code: " .. (status.code or "no code"))
      io.stderr:write("\n")
      error('Could not get github API from ' .. url)
   end

   if not data.tree then
      error("uh oh: " .. JSON.encode(data))
   end

   local tree = setmetatable({
      repo = repo,
      sha = sha,
      --fullpath = fullpath or '',
      path = path,
      name = fs.name(path) or "",
      parent = parent,
      size = 0,
      blobsCount = 0,
      treesCount = 0,
      blobs = {},
      trees = {},
      __trees = {},
   }, Tree)

   for _, childdata in ipairs(data.tree) do ---@cast childdata rawdata
      if isExclude(childdata.path, repo.excluded) then
         goto continue
      end
      if childdata.type == 'tree' then
         tree.treesCount = tree.treesCount + 1
         tree.trees[childdata.path] = childdata
         childdata.parent = tree
      end
      if childdata.type == "blob" then
         tree.blobsCount = tree.blobsCount + 1
         tree.size = tree.size + childdata.size
         tree.blobs[childdata.path] = childdata
         childdata.parent = tree
      end
      ::continue::
   end

   return tree
end

---@param path string
---@param recursively? boolean
function Tree:getChildTree(path, recursively)
   if self.__trees[path] then
      return self.__trees[path]
   end

   local rawdata = self.trees[path]
   if rawdata then
      local tree = Tree.new(self.repo, rawdata, recursively)
      self.__trees[path] = tree
      return tree
   end
   return nil
end

---@return Tree
function Tree:getRoot()
   if self.parent then
      return self.parent:getRoot()
   else
      return self
   end
end

---@param f fun(file:rawdata)
function Tree:foreachFiles(f)
   for path, data in pairs(self.blobs) do
      f(data)
   end
end

---@param dest string
---@param onProgress? fun(tree:Tree, file:string)
function Tree:cloneTo(dest, onProgress)
   if not fs.exists(dest) then
      fs.makeDirectory(dest)
   elseif not fs.isDirectory(dest) then
      return error("Destination is a file!")
   end

   for path in pairs(self.blobs) do
      local fullpath = fs.concat(dest, path)
      local subfolder = fs.path(fullpath)
      if not fs.exists(subfolder) then
         fs.makeDirectory(subfolder)
      end
      downloadFile(self.repo, self.path .. "/" .. path, fullpath)
      if onProgress then onProgress(self, path) end
   end
end

-- A class for a repo
---@class repo
---@field user string
---@field name string
---@field token? token
---@field sha string -- branch or tag
---@field subdir string
---@field excluded table<string, boolean>
---@field branches table<string, Tree>
local Repository = {}

Repository.__index = Repository
---@type table<string, repo>
Repository.__repoPriv = {}

---@param url string
---@param token token
---@return string
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
---@param opt? {token?:token, tag?:string, branch?:string, latestRelease?:boolean, excluded?:table<string, boolean>}
---@return repo
function Repository.get(owner, repo, opt)
   opt = opt or {}
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
   if not Repository.__repoPriv[owner .. "/" .. repo] then
      r = setmetatable(
         {
            user = owner,
            name = repo,
            token = opt.token,
            sha = sha,
            excluded = opt.excluded or {},
            branches = {},
         }, Repository)
      Repository.__repoPriv[owner .. "/" .. repo] = r
   else
      r = Repository.__repoPriv[owner .. "/" .. repo]
      r.sha = sha
      r.token = opt.token or r.token
   end

   if not r.branches[sha] or (opt.excluded and not same_table(r.excluded, opt.excluded)) then
      r.excluded = opt.excluded or r.excluded
      r.branches[sha] = Tree.new(r, sha, true)
   end
   return r
end

function Repository:getRepoSize()
   return self.branches[self.sha].size
end

---@param sha string
function Repository:changeBranch(sha)
   self.sha = sha
   if not self.branches[sha] then
      self.branches[sha] = Tree.new(self, sha)
   end
end

function Repository:changeToLatestRelease()
   local sha = releaseFromURL(('repos/%s/%s/releases/latest'):format(self.user, self.name), self.token)
   self.sha = sha
   if not self.branches[sha] then
      self.branches[sha] = Tree.new(self, sha)
   end
end

function Repository:changeTag(tag)
   local sha = releaseFromURL(('repos/%s/%s/releases/tags/%s'):format(self.user, self.name, tag), self.token)
   self.sha = sha
   if not self.branches[sha] then
      self.branches[sha] = Tree.new(self, sha)
   end
end

---@param dest string
---@param onProgress? fun(tree:Tree, file:string)
---@param subdir? string
function Repository:cloneTo(dest, onProgress, subdir)
   local tree = self.branches[self.sha] ---@type Tree?
   if not tree then
      error("not tree found for this sha: " .. self.sha)
   end

   if subdir then
      checkArg(3, subdir, "string")
      tree = tree:getChildTree(subdir)
      if not tree then
         error("not tree found at " .. subdir)
      end
   end

   tree:cloneTo(dest, onProgress)
end

---@param path string
---@param recursively? boolean
function Repository:getTree(path, recursively)
   checkArg(1, path, "string")
   local tree = self.branches[self.sha] ---@type Tree?
   if not tree then
      error("not tree found for this sha: " .. self.sha)
   end
   return tree:getChildTree(path, recursively)
end

---@param path string
---@param dest string
---@return boolean success
---@return string? error
function Repository:downloadFile(path, dest)
   return downloadFile(self, path, dest)
end

function Repository:__tostring()
   return ("Repo@%s/%s"):format(self.user, self.name)
end

-- Export members
local github = {}

---@param depoName string
---@param branch string
---@param path string
---@param dest string
---@return boolean success
---@return string? error
github.downloadFile = function(depoName, branch, path, dest)
   local user, repo = depoName:match('^(.+)/(.+)$') ---@type string, string
   if not user or not repo then
      error("depoName form like <user>/<repo>")
   end
   freeMemory()
   local url = ('https://raw.githubusercontent.com/%s/%s/%s/%s'):format(user, repo, branch, encodeURI(path))
   local handle = inet.request(url, nil)
   if handle.response() ~= 200 then
      return false, 'Could not get file from ' .. url.. " code: " .. tostring(handle.response())
   end
   local h, reason = io.open(dest, 'w')
   if h then
      for chunk in handle do
         h:write(chunk)
         freeMemory()
      end
      h:close()
   else
      error(reason)
   end
   return true
end


--github.Repository = Repository
--github.Tree = Tree
github.Auth = Auth
github.repo = Repository.get
return github
