local C = {}
C.Version = 3
C.MapLayout = {
 Revision=2,PlotX=190,PlotStartZ=440,RowSpacing=244,Rows=4,PlotY=1,
 CorridorOffset=660,CorridorStart=1260,CorridorEnd=2610,
 GroundCenterZ=320,GroundDepth=2040,RoadWidth=32,RoadStart=115,RoadEnd=1310,CliffExtra=40,
}
C.Grid = 4
C.PlotHalf = 72
C.LegacyPlotHalf = 80
function C.PlotHalfFor(plot)
 local half=plot and plot:GetAttribute("PlotHalf")
 return half==C.LegacyPlotHalf and C.LegacyPlotHalf or C.PlotHalf
end
C.MaxHabitats = 8
C.MaxBuilds = 180
C.WalkSpeed = 20
C.CarryMultiplier = .9
C.Species = {
 {Name="Pintinho",Biome="Campo",Resource="Penas douradas",Rate=8,Hatch=10,Speed=12,Damage=8,Color=Color3.fromRGB(255,211,69),Ground=Color3.fromRGB(105,205,65)},
 {Name="Coruja Folha",Biome="Floresta",Resource="Plumas vegetais",Rate=22,Hatch=15,Speed=16,Damage=12,Color=Color3.fromRGB(91,192,111),Ground=Color3.fromRGB(55,133,74)},
 {Name="Sapo Mutante",Biome="Pântano",Resource="Gosma",Rate=55,Hatch=20,Speed=20,Damage=16,Color=Color3.fromRGB(166,220,64),Ground=Color3.fromRGB(89,112,75)},
 {Name="Raptor Fóssil",Biome="Deserto",Resource="Fragmentos fósseis",Rate=125,Hatch=25,Speed=24,Damage=20,Color=Color3.fromRGB(224,159,86),Ground=Color3.fromRGB(226,192,111)},
 {Name="Pinguim Cristal",Biome="Gelo",Resource="Cristais",Rate=300,Hatch=30,Speed=28,Damage=24,Color=Color3.fromRGB(102,214,252),Ground=Color3.fromRGB(180,229,245)},
 {Name="Dragão de Brasa",Biome="Vulcão",Resource="Brasas",Rate=700,Hatch=40,Speed=32,Damage=28,Color=Color3.fromRGB(249,108,54),Ground=Color3.fromRGB(67,57,64)},
 {Name="Fênix do Vazio",Biome="Vazio",Resource="Essência",Rate=1600,Hatch=50,Speed=36,Damage=34,Color=Color3.fromRGB(189,104,251),Ground=Color3.fromRGB(49,41,79)},
}
C.Items = {
 Habitat={Name="Habitat",W=24,D=24,Price=500,Color=Color3.fromRGB(99,196,108),Out={0,-16}},
 Incubator={Name="Incubadora",W=12,D=12,Price=1000,Color=Color3.fromRGB(110,216,255)},
 Processor={Name="Processador",W=12,D=12,Price=1500,Color=Color3.fromRGB(255,182,74),In={0,8},Out={0,-8}},
 Seller={Name="Vendedor",W=12,D=12,Price=1000,Color=Color3.fromRGB(98,232,166),In={0,8}},
 Belt={Name="Esteira reta",W=4,D=4,Price=10,Color=Color3.fromRGB(74,96,116),Inputs={{0,4}},Out={0,-4}},
 Curve={Name="Esteira curva",W=4,D=4,Price=10,Color=Color3.fromRGB(74,96,116),Inputs={{-4,0}},Out={0,-4}},
 Merge={Name="Junção",W=4,D=4,Price=20,Color=Color3.fromRGB(74,96,116),Inputs={{0,4},{-4,0},{4,0}},Out={0,-4}},
}
C.BatteryHP={200,450,900,1800}
C.BatteryPrices={5000,25000,100000}
C.DefensesPrice=0 -- The starter walls/roof kit is assembled explicitly by its owner.
C.BreachTime=30
C.CombatLock=10
C.SpeedPrices={500,1500,4500,13500,40500}
C.SpeedIncrement=4
C.ProcessorPrices={2500,15000}
C.ProcessorMultipliers={1,1.5,2}
C.HabitatPrices={1500,7500,30000}
C.HabitatMultipliers={1,1.25,1.5,1.75}
C.ProgressStatCap=1000000000
C.Missions={
 {Id="first_hatch",Name="Um novo companheiro",Description="Incube seu primeiro ovo e veja a criatura nascer.",Stat="Hatches",Target=1,Rewards={Belt=10}},
 {Id="first_sale",Name="Primeira venda",Description="Leve um recurso pelo processador até o vendedor.",Stat="Sales",Target=1,Rewards={Curve=4}},
 {Id="busy_factory",Name="Fábrica em movimento",Description="Produza, processe e venda 25 recursos.",Stat="ResourcesSold",Target=25,Rewards={Merge=2}},
 {Id="explorer",Name="Explorador dos biomas",Description="Descubra três espécies diferentes.",Stat="Discoveries",Target=3,Rewards={Incubator=1}},
 {Id="engineer",Name="Engenheiro do tycoon",Description="Compre três melhorias de habitat.",Stat="HabitatUpgrades",Target=3,Rewards={Processor=1}},
 {Id="defender",Name="Quebre a defesa",Description="Destrua a bateria de outra base.",Stat="BatteriesBroken",Target=1,Rewards={Belt=20}},
 {Id="collector",Name="Coleção completa",Description="Descubra as sete criaturas originais.",Stat="Discoveries",Target=7,Rewards={Curve=10,Merge=4}},
}
C.RebirthCost=150000
C.RebirthMultiplier=.25
C.WeaponPrices={2500,20000}
C.Weapons={
 Baton={Name="Bastão",Damage=20,Range=8,Cooldown=.7,Energy=0},
 Blaster={Name="Blaster",Damage=20,Range=100,Cooldown=.5,Energy=12},
 BlasterPlus={Name="Blaster +",Damage=30,Range=120,Cooldown=.4,Energy=14},
}
C.StarterInventory={Habitat=1,Incubator=1,Processor=1,Seller=1,Belt=20,Curve=4,Merge=2}
C.DataStoreName="EggTycoonV3_DEV_v1"
C.ProfileLease=180
C.AutoSave=45
function C.IsSafe(p)
 return (math.abs(p.X)<=115 and math.abs(p.Z)<=115)
  or (math.abs(p.X)<=90 and p.Z>=C.MapLayout.CorridorStart and p.Z<=C.MapLayout.CorridorEnd)
end
function C.PlotCFrame(id)
 local layout=C.MapLayout
 local side=id%2==1 and -1 or 1
 local row=math.floor((id-1)/2)
 local p=Vector3.new(side*layout.PlotX,layout.PlotY,layout.PlotStartZ+row*layout.RowSpacing)
 return CFrame.lookAt(p,Vector3.new(0,p.Y,p.Z))
end
function C.ItemCFrame(cf,b)
 return cf*CFrame.new(b.X,0,b.Z)*CFrame.Angles(0,(b.R or 0)*math.pi/2,0)
end
return C
