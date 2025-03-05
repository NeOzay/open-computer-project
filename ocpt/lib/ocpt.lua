local component = require("component")
local computer = require("computer")
local event = require("event")
local filesystem = require("filesystem")
local serial = require("serialization")
local shell = require("shell")
local term = require("term")

local internet
if component.isAvailable("internet") then
   internet = require("internet")
end

local hasGithub, github = pcall(require, "github")

local options = {
   nocache = false, --useless
   offline = (not (internet and hasGithub)),
}

local wget
local function downloadFile(url, path)
   if not wget then
      wget = loadfile("/bin/wget.lua")
      if not wget then
         error("Could not find wget.lua")
      end
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

---@param handle file*
---@overload fun(handle: number, proxy: filesystem): string
local function readall(handle, proxy)
   local data = {}
   local chunk
   if proxy then
      repeat
         ---@diagnostic disable-next-line: param-type-mismatch
         chunk = proxy.read(handle, math.huge)
         data[#data + 1] = chunk
      until not chunk
      return table.concat(data, "\n")
   end

   repeat
      chunk = handle:read(math.huge)
      data[#data + 1] = chunk
   until not chunk
   return table.concat(data, "\n")
end

---@param path string
---@return string
local function readFile(path)
   local file, msg = io.open(path, "rb")
   if not file then
      error("Error while trying to read file at " .. path .. ": " .. msg)
   end
   local s = readall(file)
   file:close()
   return s
end

local _cache ---@type opdata.svd
---@return opdata.svd
local function getCache()
   if not _cache then
      local path = "/etc/opdata.svd"
      if not filesystem.exists(path) then
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

local _config ---@type oppm.cfg
---@return oppm.cfg
local function getConfig()
   if not _config then
      local path = "/etc/oppm.cfg"
      if not filesystem.exists(path) then
         local tProcess = os.getenv("_")
         tProcess = tProcess or error("Unable to get the current process")
         local _, locate = filesystem.get(tProcess)
         path = filesystem.concat(locate, "/etc/oppm.cfg")
      end
      if not filesystem.exists(path) then
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

local function isvalidFilesystem(address)
   local proxy = component.proxy(address) ---@cast proxy filesystem
   return proxy.list("/")[1] == nil or proxy.exists("/programs.cfg")
end

---@return string[]
local function getAvailableFilesystem()
   local filesystems = {} ---@type string[]
   local tmpfs = computer.tmpAddress()
   for address, type in component.list("filesystem") do
      if address ~= tmpfs then
         if isvalidFilesystem(address) then
            filesystems[#filesystems + 1] = address
         end
      end
   end
   return filesystems
end

---@param address string
---@return table<string, oppm.package>?
local function getProgramsFile(address)
   local proxy = component.proxy(address, "filesystem")
   if proxy.exists("/programs.cfg") then
      local file = proxy.open("/programs.cfg")
      local s = readall(file, proxy)
      proxy.close(file)
      return unserialize(s)
   end
end

local function saveProgramsFile(address, data)
   local proxy = component.proxy(address, "filesystem")
   local file = proxy.open("/programs.cfg", "w")
   if not file then
      error("Failed to open file for writing")
   end
   proxy.write(file, serial.serialize(data))
   proxy.close(file)
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

local getAvailablePackages =
---@param repo string
---@return table<string, oppm.package>?
    function(repo)
       if options.offline then
          local packs = {}
          local disk = getAvailableFilesystem()
          for _, address in ipairs(disk) do
             local programs = getProgramsFile(address)
             if programs then
                for name, info in pairs(programs) do
                   packs[name] = info
                end
             end
          end
          return packs
       end
       local success, sPackages = pcall(getContent,
          "https://raw.githubusercontent.com/" .. repo .. "/master/programs.cfg")
       if not success or not sPackages or sPackages == "" then
          io.stderr:write("Error while trying to get programs.cfg file for " .. repo .. "\n")
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


---@param package oppt.package.handler
local function resolveFiles(package)
   if options.offline then
      return package.info.files
   end

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
            local fullPathUrl = filesystem.concat(branch, tree.path, file.path)
            files[fullPathUrl] = target
         end)
      else
         io.stderr:write("path use " .. clearPath .. "\n")
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
local function PackageNew(repo, packName, packageInfo)
   local self = setmetatable({}, Package)
   if not options.offline then
      local owner, reponame = string.match(repo, "([^/]+)/([^/]+)")
      if not owner and not reponame then
         error("Invalid repository name")
      end
      self.repo = github.repo(owner, reponame)
   end
   self.repoName   = repo
   self.pack       = packName
   self.info       = packageInfo
   self.filescount = 0
   self.files      = resolveFiles(self)
   return self
end

local f
local _packRepoCache = {} ---@type table<string, string>
--local _packNameCache = {} ---@type table<string, oppm.package>
local _packObjectCache = {} ---@type table<string, oppt.package.handler>
---@param pack string
---@return oppt.package.handler?
local function getPackage(pack)
   if _packObjectCache[pack] then
      return _packObjectCache[pack]
   end
   if _packRepoCache[pack] then
      local infos = getAvailablePackages(_packRepoCache[pack])
      if infos and infos[pack] then
         return PackageNew(_packRepoCache[pack], pack, infos[pack])
      else
         error("Error while trying to get cached package " .. pack)
      end
   end
   if not f then
      local repos = getAvailableRepos()
      f = coroutine.create(
      ---@param _pack string
         function(_pack)
            for _, j in pairs(repos) do
               if not j.repo then
                  goto continue
               end
               local packlist = getAvailablePackages(j.repo)
               if packlist == nil then
                  io.stderr:write("Error while trying to receive packages list for " .. j.repo .. "\n")
                  goto continue
               end
               if type(packlist) == "table" then
                  for name, info in pairs(packlist) do
                     _packRepoCache[name] = j.repo
                     if name == _pack then
                        local p = PackageNew(j.repo, name, info)
                        _packObjectCache[_pack] = p
                        _pack = coroutine.yield(p)
                     end
                  end
               end
               ::continue::
            end
         end)
   end
   if coroutine.status(f) ~= "dead" then
      local success, p = coroutine.resume(f, pack)
      return p
   end
   return nil
end

---@param pack string
---@return oppt.package.handler?
function Package.getPackage(pack)
   if _packObjectCache[pack] then
      return _packObjectCache[pack]
   end
   if options.offline then
      local disk = getAvailableFilesystem()
      for _, address in ipairs(disk) do
         local programs = getProgramsFile(address)
         if programs then
            for name, info in pairs(programs) do
               if name == pack then
                  local p = PackageNew(address, name, info)
                  _packObjectCache[pack] = p
                  return p
               end
            end
         end
      end
   end
   local lRepos = getConfig()
   for repo, data in pairs(lRepos.repos) do
      for name, info in pairs(data) do
         if name == pack then
            local p = PackageNew(repo, name, info)
            _packObjectCache[pack] = p
            return p
         end
      end
   end
   return getPackage(pack)
end

---@param installed? boolean
---@param filter? string
---@return string[]
function Package.list(installed, filter)
   if filter then
      filter = string.lower(filter)
   end
   local packages = {} ---@type string[]
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
      if options.offline then
         local packs = getAvailablePackages("")
         if not packs then error("Error while trying to get packages available for offline mode") end
         for k, kt in pairs(packs) do
            if not kt.hidden then
               table.insert(packages, k)
            end
         end
      else
         local repos = getAvailableRepos()
         for _, j in pairs(repos) do
            if j.repo then
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
         if config.repos and not options.offline then
            for _, j in pairs(config.repos) do
               for k, kt in pairs(j) do
                  if not kt.hidden then
                     table.insert(packages, k)
                  end
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

local function sanitize_path(path)
   local sanitized = path:gsub("[^%w%._%/%\\%- ]", "_")
   return sanitized
end

---@param dest string
---@param force boolean?
---@return boolean success
---@return string? msg
function Package:install(dest, force)
   local success, reason = true, nil ---@type boolean, string?
   local cache = getCache()
   local config = getConfig()
   dest = dest or config.path
   dest = shell.resolve(dest)
   local pack = self.pack

   if cache[pack] then
      return true, "Package has already been installed"
   end

   if filesystem.exists(dest) then
      if not filesystem.isDirectory(dest) then
         return false, "Path points to a file, needs to be a directory."
      end
   elseif force then
      filesystem.makeDirectory(dest)
   else
      return false, "Destination does not exist."
   end

   cache[pack] = {}
   ---@param address string
   ---@param from string
   ---@param to string
   ---@return boolean
   ---@return string?
   local function copy(address, from, to)
      local proxy = component.proxy(address) ---@cast proxy filesystem
      local data
      local input = proxy.open(from, "rb")
      if input then
         local output = filesystem.open(to, "wb")
         if output then
            repeat
               data, reason = proxy.read(input, 1024)
               if not data then break end
               data, reason = output:write(data)
               if not data then data, reason = false, "failed to write" end
            until not data
            output:close()
         end
         proxy.close(input)
      end
      return data == nil, reason
   end

   for file, target in pairs(self.files) do
      local localPath
      local branch, repoPath = string.match(file, "^%??(.-)/(.+)")
      if string.find(target, "^//") then -- absolute path
         local lPath = string.sub(target, 2)
         if not filesystem.exists(lPath) then
            filesystem.makeDirectory(lPath)
         end
         localPath = filesystem.concat(lPath, gsub(repoPath, ".+(/.-)$", "%1"))
      else
         local lPath = filesystem.concat(dest, target) -- relative path
         if not filesystem.exists(lPath) then
            filesystem.makeDirectory(lPath)
         end
         localPath = filesystem.concat(lPath, gsub(repoPath, ".+(/.-)$", "%1"))
      end

      local soft = string.find(file, "^%?") and filesystem.exists(localPath) and not force or false
      if soft then
         goto continue
      end
      if options.offline then
         success, reason = copy(self.repoName, filesystem.concat(self.pack, branch, repoPath), localPath)
      else
         self.repo:changeBranch(branch)
         success, reason = self.repo:downloadFile(repoPath, localPath)
      end

      cache[pack][file] = localPath
      if not success then
         break
      end
      ::continue::
   end

   if self.info.dependencies and success then
      for dep, target in pairs(self.info.dependencies) do
         term.write("Done.\nInstalling Dependencies " .. dep .. ":...\n")
         local localPath
         if string.find(target, "^//") then
            localPath = string.sub(target, 2)
         else
            localPath = filesystem.concat(dest, target)
         end
         if string.lower(string.sub(dep, 1, 4)) == "http" then
            localPath = filesystem.concat(localPath, gsub(dep, ".+(/.-)$", "%1"), nil)
            if not filesystem.exists(filesystem.path(localPath)) then
               filesystem.makeDirectory(filesystem.path(localPath))
            end
            if options.offline then
               success, reason = copy(self.repoName, sanitize_path(dep), localPath)
            else
               success = pcall(downloadFile, dep, localPath)
            end
            if success then
               cache[pack][dep] = localPath
               saveCache(cache)
            else
               term.write("Error while downloading files for package '" ..
                  dep .. "'" .. ". Reverting installation... ")
               filesystem.remove(localPath)
               for o, p in pairs(cache[dep]) do
                  filesystem.remove(p)
                  cache[dep][o] = nil
               end
               print("Done.\nPlease contact the package author about this problem.")
            end
         else
            local depPack = Package.getPackage(string.lower(dep))
            if not depPack then
               success, reason = false, ("\nDependency package " .. dep .. " does not exist.")
            else
               success, reason = depPack:install(localPath, force)
            end
         end
         if not success then
            break
         end
      end
   end
   if not success then
      term.write("Error while installing files for package '" .. pack .. "': " ..
         reason .. ".\nReverting installation...\n")
      for o, p in pairs(cache[pack]) do
         filesystem.remove(p)
         cache[pack][o] = nil
      end
      cache[pack] = nil
      return false, "Error while installing files for package '" .. pack .. "':\n\t" .. reason
   end
   saveCache(cache)
   return true
end

---@param address string
---@return boolean success
---@return string? msg
function Package:addToDisk(address)
   local fs = component.proxy(address)
   if fs.type ~= "filesystem" or not isvalidFilesystem(address) then
      return false, "Invalid filesystem"
   end
   ---@cast fs filesystem
   local programs
   if fs.exists("/programs.cfg") then
      programs = getProgramsFile(address)
      if not programs then
         error("Error while trying to get programs.cfg file of " .. fs.address)
      end
   else
      programs = {}
   end
   if programs[self.pack] then
      return false, "Package already exists on disk"
   end
   programs[self.pack] = self.info
   programs[self.pack].files = self.files
   saveProgramsFile(address, programs)
   if not programs["ocpt"] then
      io.stdout:write("ocpt package not found on disk. Try to add it first.\n")
      local ocpt = Package.getPackage("ocpt")
      if ocpt then
         local success, err = ocpt:addToDisk(address)
         if not success then
            io.stderr:write("Error while trying to add ocpt to disk: " .. err .. "\n")
         else
            local disk = component.proxy(address, "filesystem")
            local handle = disk.open("/.prop", "w")
            disk.write(handle, '{ fromDir = "/ocpt/master/ocpt", root = "/usr", label = "ocpt", }')
            disk.close(handle)
            io.stdout:write("ocpt package added successfully\n")
         end
      else
         io.stderr:write("unable to find ocpt package\n")
      end
   end
   local disk = filesystem.concat("/mnt/" .. fs.address:sub(1, 3), self.pack)
   if filesystem.exists(disk) then
      return false, "directory already exists"
   end
   for file, _ in pairs(self.files) do
      local branch, repoPath = string.match(file, "^%??(.-)/(.+)")
      local target = filesystem.concat(disk, branch, repoPath)
      if not filesystem.exists(filesystem.path(target)) then
         filesystem.makeDirectory(filesystem.path(target))
      end
      self.repo:changeBranch(branch)
      local success, msg = self.repo:downloadFile(repoPath, target)
      if not success then
         return false, "Error while downloading file '" .. repoPath .. "': " .. msg
      end
   end
   if self.info.dependencies then
      for depName in pairs(self.info.dependencies) do
         print("Installing dependency " .. depName)
         if string.lower(string.sub(depName, 1, 4)) == "http" then
            local sanetized = sanitize_path(depName)
            sanetized = filesystem.concat("/mnt/" .. fs.address:sub(1, 3), sanetized)
            if not filesystem.exists(filesystem.path(sanetized)) then
               filesystem.makeDirectory(filesystem.path(sanetized))
            end
            local success = pcall(downloadFile, depName, sanetized)
            if not success then
               return false, "Error while trying to install dependency package " .. depName
            end
         else
            local dep = Package.getPackage(depName)
            if dep then
               local success, err = dep:addToDisk(address)
               if not success then
                  return false, "Error while trying to install dependency package " .. depName .. ": " .. err
               end
            else
               return false, "Dependency package " .. depName .. " does not found."
            end
         end
      end
   end
   return true
end

---@param address string
---@return boolean success
---@return string? msg
function Package:removeToDisk(address)
   local fs = component.proxy(address)
   if fs.type ~= "filesystem" and isvalidFilesystem(address) then
      return false, "Invalid filesystem"
   end
   ---@cast fs filesystem
   local programs
   if not fs.exists("/programs.cfg") then
      return false, "No programs.cfg file found on disk"
   end
   programs = getProgramsFile(address)
   if not programs or programs and not programs[self.pack] then
      return false, "Package does not exist on disk"
   end
   programs[self.pack] = nil
   saveProgramsFile(address, programs)
   local packLocate = filesystem.concat("/mnt/" .. fs.address:sub(1, 3), self.pack)
   filesystem.remove(packLocate)
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
         filesystem.remove(localPath)
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
            dest = gsub(filesystem.path(cache[pack][url]), target .. ".*$", "/")
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
   options = options,
}
