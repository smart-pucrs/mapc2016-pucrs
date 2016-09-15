{ include("new-round.asl") }
{ include("end-round.asl") }
{ include("common-plans.asl") }
{ include("common-rules.asl") }
{ include("common-actions.asl") }
{ include("bidder.asl") }
{ include("common-strategies.asl") }
{ include("$jacamoJar/templates/common-cartago.asl") }

!start.

+!start
	: .my_name(Me)
<-
 	.wait({ +step(_) });
	if (Me == vehicle15) {
		!start_ringing;	
	}
    .

+!register(E)
	: .my_name(Me)
<-
	!new_round;
	if (Me == vehicle15) {
		makeArtifact("teamArtifact","pucrs.agentcontest2016.env.TeamArtifact",[]);
		+max_bid_time(2000);
		+chargingPrice(0,0);
		+assembledInShops([]);
		+agentsFree(16);
		+shopExplorationInProgess;
		.include("initiator.asl");
		!create_taskboard;
		focusWhenAvailable("teamArtifact");		
	}
	focusWhenAvailable("task_board");
    .print("Registering...");
    .concat("eis_art_", Me, ArtName);
    .term2string(Me, MeS);
    makeArtifact(ArtName, "pucrs.agentcontest2016.env.EISArtifact", [], AId);
    focus(AId);
    register(E);
	.

+role(Role, Speed, LoadCap, BatteryCap, Tools)
	: .my_name(Me)
<-
	addLoad(Me,LoadCap);
	.