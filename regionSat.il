;; copyleft ebecheto
;; regionSat create AC small 'signal-like' schematic for viewing purpose (ie. documentation)
;; getHierRootName is a function equivalent to Design->Scope for hierarchy naming purpose

procedure(regionSat(@optional (idW hiGetCurrentWindow()))
let( ( Drain Gate Ibias Source VGS cv dNet downNet gNet gmVGS igm lbId rdsVal res rot sNet t_name upNet wid wireBox wireId xS xT xc yS yT yc yw )
wid=idW~>cellView

;;openResults("/data/ebecheto/Sim/buf_adaptivRes_sim/spectre/schematic")
openResults(idW~>artistSimulationDataDir)

xS=0.5 yS=0 ;<== x et y space between gm et gds
xT = 1.5;<== coefficient de translation en x
yT = 1.2 ;<==  coefficient de translation en y
yw=-0.375;<== line on the other side of the origin of res or idc

;; region 2 schematic to gm gds
res = dbOpenCellViewByType( "analogLib" "res" "symbol" "schematicSymbol" "r")
Ibias = dbOpenCellViewByType( "analogLib" "idc" "symbol" "schematicSymbol" "r")

cv = dbOpenCellViewByType( wid~>libName wid~>cellName "schematic_smallSig" "schematic" "w")
foreach(mapcar x wid~>instances 
	if( ( x~>cellName=="nmos4" || x~>cellName=="pmos4" ) then
;;	when( pv( t_name "region" ?result "dcOpInfo-info")!=0
;;		printf("pv(%s %s ?result %s)\n" x~>name "region" "dcOpInfo-info") 
 printf("BEGIN MAPCAR %s %s \n" x~>baseName x~>cellName )

	t_name=strcat(getHierRootName() x~>baseName)
	xc=car(x~>xy)*xT
	yc=cadr(x~>xy)*yT
	printf("\n %s is Saturated. Position:%L\n" t_name list(xc yc))
Gate=car(setof(term x~>instTerms term~>name=="G"))   gNet=car(Gate~>net~>sigNames)
Drain=car(setof(term x~>instTerms term~>name=="D"))  dNet=car(Drain~>net~>sigNames)
Source=car(setof(term x~>instTerms term~>name=="S")) sNet=car(Source~>net~>sigNames)
	printf("%L" list( gNet dNet sNet pv( t_name "gm" ?result "dcOpInfo-info") ))

upNet=sNet
downNet=dNet
rot="R0"
when( (x~>cellName=="nmos4") upNet=dNet downNet=sNet rot="R0" )
	printf("%L" list( upNet downNet pv( t_name "gds" ?result "dcOpInfo-info") ))

;; when ohmique, gds=KoxW/L.(Vgs-Vth-Vds) else numeric value
rdsVal=sprintf(nil "%g" 1/pv( t_name "gds" ?result "dcOpInfo-info"))
VGS=sprintf(nil "%s-%s" gNet sNet)
gmVGS=sprintf(nil "gm_%s(%s)"  x~>baseName VGS)
;;gds
(dbCreateParamInst cv res strcat("Rds_" x~>baseName) (list xc yc) "R0" 1 list(list("r" "string" rdsVal)))
when( pv( t_name "region" ?result "dcOpInfo-info")==2 
;;gm
igm=(dbCreateParamInst cv Ibias strcat("I_" x~>baseName) (list xc+xS yc+yS) rot 1 list(list("idc" "string" gmVGS)))
; when( x~>cellName=="pmos4" dbMoveFig(igm nil list(car(igm~>xy):cadr(igm~>xy) "R180")))
when( (x~>cellName=="pmos4") dbMoveFig(igm nil list(0:2*cadr(igm~>xy)+yw "MX")))
); when Saturated


wireId=car(schCreateWire( cv "draw" "direct" list(xc+xS:yc+yS xc:yc) 0.0625 0.0625 0.0125  )); <== creat wire line
if( wireId then
wireBox=((lambda (arg) (append list(caar(arg)+caadr(arg)) list(cadar(arg)+ cadadr(arg)) )) list(centerBox(wireId~>bBox) list(0 0.05) ) )
lbId=schCreateWireLabel( cv wireId wireBox upNet "lowerCenter" "R0" "fixed" 0.0625 nil ) 
else
printf("WARNING, existind wire => not created at location : %L\n" list(xc+xS:yw+yc+yS xc:yw+yc))
);; end existing wire id


wireId=car(schCreateWire( cv "draw" "direct" list(xc+xS:yw+yc+yS xc:yw+yc) 0.0625 0.0625 0.0125  )); <== creat wire line
if( wireId then
wireBox=((lambda (arg) (append list(caar(arg)+caadr(arg)) list(cadar(arg)+ cadadr(arg)) )) list(centerBox(wireId~>bBox) list(0 -0.1) ) )
lbId=schCreateWireLabel( cv wireId wireBox downNet "lowerCenter" "R0" "fixed" 0.0625 nil )
else
printf("WARNING, existind wire => not created at location : %L\n" list(xc+xS:yw+yc+yS xc:yw+yc))
);; end existing wire id

;; ?? );when not bloked
else ;; resistance, capa ...
 when( x~>cellName!="iopin"  
printf("!IO %L \n"  list(x~>cellName centerBox(wireId~>bBox)))
(schCopy x cv (list car(x~>xy)*(xT-1):cadr(x~>xy)*(yT-1)  "R0")) 
)
); if nmos4||pmos4 saturated
); foreach
dbSave(cv) 
geOpen(?lib cv~>libName ?cell cv~>cellName ?view "schematic_smallSig" ?mode "r")
;; dbClose(cv)
simulator('spectre)
);end let
);end proc
;; load("~/../ebecheto/Skill/regionSat.il")

procedure(getHierRootName(@optional (idWin hiGetCurrentWindow()))
let((hierInstName i)
    hierInstName=""
    when( geGetHierMemInst(idWin)
	i=0
        printf("Hierarchical Scope is :%s\n " caar(geGetHierMemInst(idWin))~>cellView~>cellName)
	printf("depth is :%d\n" length(geGetHierMemInst(idWin)))
        foreach(mapcar hierNb geGetHierMemInst(idWin)
	        hierInstName=strcat(hierInstName car(hierNb)~>baseName)
        	printf("%L\n" hierNb)
        	printf("Level %d %L~>baseName:%L\n" i car(hierNb) list(hierInstName car(hierNb)~>baseName))
        	when((cadr(hierNb)!=0) hierInstName=sprintf(nil "%s<%d>" hierInstName cadr(hierNb)))
     		hierInstName=strcat( hierInstName ".")
        i++ 
    );end foreach
);when hierarchy
hierInstName
))
