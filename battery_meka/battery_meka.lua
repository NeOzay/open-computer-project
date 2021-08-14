local component = require("component")
local os = require("os")
local term = require("term")
local colors=require("colors")
local battery=component.induction_matrix
local gpu=component.gpu
term.clear()
gpu.setResolution(100,18)

maxEnergy=battery.getMaxEnergy()*0.4
maxTransferRate=battery.getTransferCap()*0.4

function histogram(xpos,ypos,longueur,largeur,pourcentage,couleur)
  gpu.setBackground(0x6C6C6C)
  gpu.fill(xpos,ypos,longueur,largeur," ")
  longueurP=pourcentage*longueur
  gpu.setBackground(couleur)
  gpu.fill(xpos,ypos,longueurP,largeur," ")

end

function write(xpos,ypos,text,colorB,colorF)
  gpu.setBackground(colorB)
  gpu.setForeground(colorF)
  gpu.set(xpos,ypos,text)
end

function colorsCode(pourcentage)
  for k,v in pairs(codesort) do
    if v <= pourcentage then
      return code[v]
    end
  end
end

function convertion(valeur)
  if valeur ~= 0 then
    local vlog = math.floor(math.log(valeur,10)/3)
    RF=unite[vlog+1]
    valeur = valeur*10^(-3*vlog)
    aron=math.floor(math.log(valeur,10))+1
    return string.format("%0."..tostring(4-aron).."f",valeur)
  else
    RF="  RF"
    return "0.000"
  end
end

oldpourcentage= -10
code = {[0]=0xFF0000,[30]=0xF9FF00,[50]=0x1BFF00,[95]=0x004DFF}
codesort={95,50,30,0}
unite={" RF"," kRF"," MRF"," GRF"," TRF"}

gpu.setBackground(0xF6DDCC)
gpu.fill(1,1,100,18," ")
gpu.setBackground(0x212F3D)
gpu.fill(9,11,82,4,"-")
gpu.fill(91,12,1,2,"]")
gpu.fill(9,12,1,2,"|")
write(50,9,"Output:",0x808B96,0xA93226 )
write(10,9,"Input:",0x808B96,0xA93226)
write(50,10,"Charge:",0x808B96,0xA93226)
write(10,10,"MAXCAPACITY:"..convertion(maxEnergy)..RF,0x808B96,0x212F3D)
while true do
  energy = battery.getEnergy()*0.4
  inputRate = battery.getInput()*0.4
  outputRate = battery.getOutput()*0.4
  pourcentage=energy/maxEnergy
  write(16,9,convertion(inputRate)..RF.."/t",0x808B96,0x212F3D)
  write(57,9,convertion(outputRate)..RF.."/t",0x808B96,0x212F3D)
  write(57,10,convertion(energy)..RF.." "..string.format("%3d",math.floor(pourcentage*100)).."%",0x808B96,0x212F3D)
  if math.abs(pourcentage-oldpourcentage) >= 0.05 then
    histogram(10,12,80,2,pourcentage,colorsCode(pourcentage*100))
    oldpourcentage=pourcentage
  end
  os.sleep(2)
end
