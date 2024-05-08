local component = require("component")
local event = require("event")
local fs = require("filesystem")
local serial = require("serialization")
local shell = require("shell")
local term = require("term")

local internet = require("internet")

local github = require("github")

local options = {
   nocache = false,
}
local wget
local function downloadFile(url, path)
   if not wget then
      wget = loadfile("/bin/wget.lua")
   end
   wget("-fq", url, path)
end

---@param s string
---@return any|nil
local function unserialize(s)
   local result, reason = serial.unserialize(s)
   if not result and reason then
      error("Error while trying to unserialize: " .. reason)
   end
   return result
end

--For sorting table values by alphabet
---@param a string
---@param b string
---@return boolean
local function compare(a, b)
   for i = 1, math.min(#a, #b) do
      if a:sub(i, i) ~= b:sub(i, i) then
         return a:sub(i, i) < b:sub(i, i)
      end
   end
   return #a < #b
end

local function getContent(url)
   local response = internet.request(url)
   local sContent = {}
   for chunk in response do
      table.insert(sContent, chunk)
   end
   return table.concat(sContent)
end

---@param s string|number
---@param pattern string|number
---@param repl string|number|table
---@param n? number
---@return string
local function gsub(s, pattern, repl, n)
   s = s:gsub(pattern, repl, n)
   return s
end

local NIL = {}
---@generic T
---@param f T
---@return T
local function cached(f)
   return options.nocache and f or setmetatable(
      {},
      {
         __index = function(t, k)
            local v = f(k)
            t[k] = v
            return v
         end,
         __call = function(t, k)
            if k == nil then
               k = NIL
            end
            return t[k]
         end,
      }
   )
end

---@param path string
---@return string
local function readFile(path)
   local file, msg = io.open(path, "rb")
   if not file then
      error("Error while trying to read file at " .. path .. ": " .. msg)
   end
   local s = file:read("*a")
   file:close()
   return s
end

local _cache
---@return opdata.svd
local function getCache()
   if not _cache then
      local path = "/etc/opdata.svd"
      if not fs.exists(path) then
         _cache = { _repos = {} }
         return _cache
      end
      local opdata = readFile(path)
      local success, data = pcall(unserialize, opdata)
      if success and not data then
         _cache = { _repos = {} }
         return _cache
      end
      _cache = success and data or error("Error while trying to unserialize opdata.svd:\n" .. data)
   end
   return _cache
end

local _config
---@return oppm.cfg
local function getConfig()
   if not _config then
      local path = "/etc/oppm.cfg"
      if not fs.exists(path) then
         local tProcess = os.getenv("_")
         tProcess = tProcess or error("Unable to get the current process")
         local _, locate = fs.get(tProcess)
         path = fs.concat(locate, "/etc/oppm.cfg")
      end
      if not fs.exists(path) then
         _config = { path = "/usr", repos = {} }
         return _config
      end
      local cfg = readFile(path)
      local success, data = pcall(unserialize, cfg)
      if success and not data then
         _config = { path = "/usr", repos = {} }
         return _config
      end
      _config = success and data or error("Error while trying to unserialize oppm.cfg:\n" .. data)
   end
   return _config
end

local function saveCache(packs)
   packs = packs or getCache()
   local file, msg = io.open("/etc/opdata.svd", "wb")
   if not file then
      io.stderr:write("Error while trying to save package names: " .. msg)
      return
   end
   local sPacks = serial.serialize(packs)
   file:write(sPacks)
   file:close()
end

local getAvailableRepos = cached(
---@return table<string, {repo: string}>
   function()
      local success, sRepos = pcall(getContent,
         "https://raw.githubusercontent.com/OpenPrograms/openprograms.github.io/master/repos.cfg")
      if not success or not sRepos then
         error("Could not connect to the Internet. Please ensure you have an Internet connection.")
      end
      local repos
      success, repos = pcall(unserialize, sRepos)
      if not success or not repos then
         error("Error while trying to unserialize:\n" .. repos)
      end
      local svd = getCache()
      for name, data in pairs(svd._repos) do
         if not repos[name] then
            repos[name] = data
         end
      end

      return repos
   end
)

local getAvailablePackages = cached(
---@param repo string
---@return table<string, oppm.package>?
   function(repo)
      local success, sPackages = pcall(getContent, "https://raw.githubusercontent.com/" .. repo .. "/master/programs.cfg")
      if not success or not sPackages or sPackages == "" then
         io.stderr:write("Error while trying to get programs.cfg file for "..repo.."\n")
         return
      end
      local data
      success, data = pcall(unserialize, sPackages)
      if not success or not data then
         io.stderr:write(sPackages)
         io.stderr:write("Error while trying to unserialize packages: " .. sPackages .. "\n" .. data)
         return
      end
      return data
   end
)



---@param package oppt.package.handler
local function resolveFiles(package)
   local files = {}
   ---@param path string
   ---@param target string
   local function getfiles(path, target)
      local repo = package.repo
      local branch, clearPath = string.match(path, "^(.-)/(.+)")
      repo:changeBranch(branch)
      local tree = repo:getTree(clearPath, true)
      if tree then
         tree:foreachFiles(function(file)
            local fullPathUrl = fs.concat(branch, tree.path, file.path)
            files[fullPathUrl] = target
         end)
      else
         io.stderr:write("path use " .. clearPath.."\n")
         error("Error while trying to get files from " .. path)
      end
   end
   for rawpath, target in pairs(package.info.files) do
      if string.find(rawpath, "^:") then
         rawpath = rawpath:gsub("^:", "")
         getfiles(rawpath, target)
      else
         files[rawpath] = target
      end
   end
   return files
end

---@class oppt.package.handler
---@field repo repo
---@field repoName string
---@field pack string
---@field info oppm.package
---@field filescount number
---@field files table<string, string>
local Package = {}
Package.__index = Package

---@param repo string
---@param packName string
---@param packageInfo oppm.package
function Package.new(repo, packName, packageInfo)
   local owner, reponame = string.match(repo, "([^/]+)/([^/]+)")
   if not owner and not reponame then
      error("Invalid repository name")
   end
   local self      = setmetatable({}, Package)
   self.repo       = github.repo(owner, reponame)
   self.repoName   = repo
   self.pack       = packName
   self.info       = packageInfo
   self.filescount = 0
   self.files      = resolveFiles(self)
   return self
end

---@param pack string
---@return oppt.package.handler?
function Package.getPackage(pack)
   local repos = getAvailableRepos()
   for _, j in pairs(repos) do
      if not j.repo then
         goto continue
      end
      local packlist = getAvailablePackages(j.repo)
      if packlist == nil then
         io.stderr:write("Error while trying to receive package list for " .. j.repo .. "\n")
         goto continue
      end
      if type(packlist) == "table" then
         for name, packinfo in pairs(packlist) do
            if name == pack then
               return Package.new(j.repo, name, packinfo)
            end
         end
      end
      ::continue::
   end
   local lRepos = getConfig()
   for repo, data in pairs(lRepos.repos) do
      for name, packinfo in pairs(data) do
         if name == pack then
            return Package.new(repo, name, packinfo)
         end
      end
   end

   return nil
end

---@param installed? boolean
---@param filter? string
---@return string[]
function Package.list(installed, filter)
   if filter then
      filter = string.lower(filter)
   end
   local packages = {}
   if installed then
      local lPacks = {}
      local packs = getCache()
      for i in pairs(packs) do
         if i:sub(1, 1) ~= "_" then
            table.insert(lPacks, i)
         end
      end
      packages = lPacks
   end

   if not installed then
      print("Receiving Package list...")
      local repos = getAvailableRepos()
      for _, j in pairs(repos) do
         if j.repo then
            print("Checking Repository " .. j.repo)
            local lPacks = getAvailablePackages(j.repo)
            if lPacks == nil then
               io.stderr:write("Error while trying to receive packages available for " .. j.repo .. "\n")
            elseif type(lPacks) == "table" then
               for k, kt in pairs(lPacks) do
                  if not kt.hidden then
                     table.insert(packages, k)
                  end
               end
            end
         end
      end

      local config = getConfig()
      if config.repos then
         for _, j in pairs(config.repos) do
            for k, kt in pairs(j) do
               if not kt.hidden then
                  table.insert(packages, k)
               end
            end
         end
      end
   end
   if filter then
      local lPacks = {}
      for i, j in ipairs(packages) do
         if (#j >= #filter) and string.find(j, filter, 1, true) ~= nil then
            table.insert(lPacks, j)
         end
      end
      packages = lPacks
   end
   table.sort(packages, compare)
   return packages
end

---@param dest string
---@param force boolean?
---@return boolean success
---@return string? msg
function Package:install(dest, force)
   local cache = getCache()
   local config = getConfig()
   dest = dest or config.path
   dest = shell.resolve(dest)
   local pack = self.pack

   if fs.exists(dest) then
      if not fs.isDirectory(dest) then
         return false, "Path points to a file, needs to be a directory."
      end
   elseif force then
      fs.makeDirectory(dest)
   else
      return false, "Destination does not exist."
   end

   if cache[pack] then
      return false, "Package has already been installed"
   end

   cache[pack] = {}
   --term.write("Installing Files...")
   for file, target in pairs(self.files) do
      local localPath
      local branch, repoPath = string.match(file, "^%??(.-)/(.+)")
      if string.find(target, "^//") then
         local lPath = string.sub(target, 2)
         if not fs.exists(lPath) then
            fs.makeDirectory(lPath)
         end
         localPath = fs.concat(lPath, gsub(repoPath, ".+(/.-)$", "%1"))
      else
         local lPath = fs.concat(dest, target)
         if not fs.exists(lPath) then
            fs.makeDirectory(lPath)
         end
         print("target: " .. target)
         print("lPath: " .. lPath)
         localPath = fs.concat(lPath, gsub(repoPath, ".+(/.-)$", "%1"))
      end

      local soft = string.find(file, "^%?") and fs.exists(localPath) and not force
      if soft then
         goto continue
      end
      self.repo:changeBranch(branch)
      local success, msg = self.repo:downloadFile(repoPath, localPath)
      if not success then
         term.write("Error while installing files for package '" .. pack .. "': " ..
            msg .. ".\nReverting installation...\n")
         fs.remove(localPath)
         for o, p in pairs(cache[pack]) do
            fs.remove(p)
            cache[pack][o] = nil
         end
         cache[pack] = nil
         return false, "Error while installing files for package '" .. pack .. "': " .. msg
      end
      cache[pack][file] = localPath
      ::continue::
   end

   if self.info.dependencies then
      term.write("Done.\nInstalling Dependencies...\n")
      for dep, target in pairs(self.info.dependencies) do
         local localPath
         if string.find(target, "^//") then
            localPath = string.sub(target, 2)
         else
            localPath = fs.concat(dest, target)
         end
         if string.lower(string.sub(dep, 1, 4)) == "http" then
            localPath = fs.concat(localPath, gsub(dep, ".+(/.-)$", "%1"), nil)
            if not fs.exists(fs.path(localPath)) then
               fs.makeDirectory(fs.path(localPath))
            end
            local success, response = pcall(downloadFile, dep, localPath)
            if success and response then
               cache[pack][dep] = localPath
               saveCache(cache)
            else
               response = response or "no error message"
               term.write("Error while installing files for package '" ..
                  dep .. "': " .. response .. ". Reverting installation... ")
               fs.remove(localPath)
               for o, p in pairs(cache[dep]) do
                  fs.remove(p)
                  cache[dep][o] = nil
               end
               print("Done.\nPlease contact the package author about this problem.")
            end
         else
            local depPack = Package.getPackage(string.lower(dep))
            if not depPack then
               term.write("\nDependency package " .. dep .. " does not exist.")
            else
               depPack:install(localPath, force)
            end
         end
      end
   end
   saveCache(cache)
   return true
end

---@param pack string
---@param removeAll boolean? @also remove config files
---@return boolean success
---@return string? msg
function Package.uninstall(pack, removeAll)
   removeAll = removeAll or false
   local cache = getCache()
   if not cache[pack] then
      return false, "Package has not been installed."
   elseif pack:sub(1, 1) == "_" then
      return false, "Invalid package name."
   end
   for url, localPath in pairs(cache[pack]) do
      if not string.find(url, "^%?") or removeAll then
         fs.remove(localPath)
      end
   end
   cache[pack] = nil
   saveCache(cache)
   return true
end

---@param pack string
---@return boolean success
---@return string? msg
function Package.update(pack)
   local cache = getCache()
   if not cache[pack] then
      return false, "Package has not been installed."
   end
   local dest
   local packObj = Package.getPackage(pack)
   if not packObj then
      return false, "Unable to find package: " .. pack
   end
   for url, target in pairs(packObj.files) do
      if not string.find(target, "^//") then
         if cache[pack][url] then
            dest = gsub(fs.path(cache[pack][url]), target .. ".*$", "/")
            break
         end
      end
   end
   dest = shell.resolve(gsub(dest, "^/?", "/"), nil)
   local success, msg = Package.uninstall(pack)
   if success then
      success, msg = packObj:install(dest)
      if not success then
         return false, "Error while trying to update package: " .. (msg or "no error message")
      end
      return true
   else
      return false, "Error while trying to uninstall package: " .. (msg or "no error message")
   end
end

---@return boolean success
---@return string? msg
function Package.updateAll()
   local cache = getCache()
   local done = false
   local msgs = {}
   for pack in pairs(cache) do
      if pack:sub(1, 1) ~= "_" then
         local success, msg = Package.update(pack)
         if not success then
            table.insert(msgs, msg)
         end
         done = true
      end
   end
   if not done then
      return false, "No package has been installed so far."
   end
   if #msgs >= 1 then
      return false, table.concat(msgs, "\n")
   end
   return true
end

---@param repo string
---@return boolean success
---@return string? msg
local function registerRepo(repo)
   local packs = getAvailablePackages(repo)
   if not packs then
      return false, "Repository " .. repo .. " not found or not containing programs.cfg"
   end
   local svd = getCache()
   if svd._repos[repo] then
      return false, "Repository " .. repo .. " already registered"
   else
      svd._repos[repo] = { ["repo"] = repo }
      saveCache(svd)
   end
   return true
end

---@param repo string
---@return boolean success
---@return string? msg
local function unregisterRepo(repo)
   local svd = getCache()
   if not svd._repos[repo] then
      return false, "Repository " .. repo .. " not registered"
   end
   svd._repos[repo] = nil
   saveCache(svd)
   return true
end

return {
   list = Package.list,
   uninstall = Package.uninstall,
   update = Package.update,
   updateAll = Package.updateAll,
   getPackage = Package.getPackage,
   registerRepo = registerRepo,
   unregisterRepo = unregisterRepo,
}
