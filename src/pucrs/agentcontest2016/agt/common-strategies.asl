+!go_dump
	: dumpList(List)
<-
	?closest_facility(List,Facility);
	!goto(Facility);
	for (item(ItemId,Qty)) {
 		!dump(ItemId,Qty);
 		while (lastActionResult(ActionResult) & Result == failed_random) {
			.print("Dump failed, executing it again.");
			!dump(ItemId,Qty);
		}
 	}
	.
	 
+!go_work(JobId,StorageId)
	: buyList(_,_,ShopId) & .my_name(Me) & role(_, _, LoadCap, _, _)
<-
	!goto(ShopId);
	.drop_desire(goto(_));
	for ( buyList(Item2,Qty2,ShopId) ) { 
		while ( buyList(Item,Qty,ShopId) ) {
			!buy(Item,Qty);
			!skip;
		}
	}
	!goto(StorageId);
	!deliver_job(JobId);
	while (lastActionResult(ActionResult) & ActionResult == failed_random) {
		.print("Deliver Job failed, executing it again.");
		!deliver_job(JobId);
	}
	!deliver_job(JobId);
	if (lastActionResult(ActionResult2) & (ActionResult2 == useless | ActionResult2 == failed_job_status) & load(Load) & Load \== 0) {
		!go_dump;
	}
	.send(vehicle15,tell,done(JobId));
	updateLoad(Me,LoadCap);
	?winner(List,JobId,StorageId,ShopId)[source(X)];
	-winner(List,JobId,StorageId,ShopId)[source(X)];
	!free;
	.
	
+!go_charge(FacilityId)
	:  chargingList(List) & lat(Lat) & lon(Lon) & getFacility(FacilityId,Flat,Flon,Aux1,Aux2) & role(_, Speed, _, BatteryCap, _)
<-
	+onMyWay([]);
	?inFacility(Fac);
	if (.member(Fac,List)) {
		.delete(Fac,List,List2);
	}
	else {
		List2 = List;
	}
	for(.member(ChargingId,List2)){
		?chargingStation(ChargingId,Clat,Clon,_,_,_);
		if(math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Lat-Clat)**2+(Lon-Clon)**2)) & math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Clat-Flat)**2+(Clon-Flon)**2))){
			?onMyWay(AuxList);
			-onMyWay(AuxList);
			+onMyWay([ChargingId|AuxList]);
		}
	}
	?onMyWay(Aux2List);
	if(.empty(Aux2List)){
		?closest_facility(List2,Facility);
		?closest_facility(List,FacilityId,FacilityId2);
//		?enough_battery_charging2(Facility, FacilityId, Result, BatteryCap);
		?enough_battery2(Facility, FacilityId, FacilityId2, Result, BatteryCap);
		if (not Result) {
			+going(FacilityId); 
			+impossible;
			.print("@@@@ Impossible route, going to try anyway and hopefully call service breakdown.");
			!commitAction(goto(facility(FacilityId)));
			!commitAction(goto(facility(FacilityId)));
		}
		else {
			FacilityAux2 = Facility;
			.print("There is no charging station between me and my goal, going to the nearest one.");
		}
	}
	else{
		?closest_facility(Aux2List,Facility);
		?enough_battery_charging(Facility, Result);
		if (not Result) {
			?closest_facility(List2,FacilityAux);
			?enough_battery_charging2(FacilityAux, Facility, Result, BatteryCap);
			if (not Result) {
				+going(FacilityId); 
				+impossible;
				.print("@@@@ Impossible route, going to try anyway and hopefully call service breakdown.");
				!commitAction(goto(facility(FacilityId)));
				!commitAction(goto(facility(FacilityId)));
			}
			else {
				FacilityAux2 = FacilityAux;
				.print("There is no charging station between me and my goal, going to the nearest one.");
			}
		}
		else {
			?closest_facility(Aux2List,FacilityId,FacilityAux);
			?enough_battery_charging(FacilityAux, ResultAux);
			if (ResultAux) {
				FacilityAux2 = FacilityAux;
			}
			else {
				.delete(FacilityAux,Aux2List,Aux2List2);
				!check_list_charging(Aux2List2,FacilityId);
				?charge_in(FacAux);
				-charge_in(FacAux);
				FacilityAux2 = FacAux;
			}
		}
	}
	-onMyWay(Aux2List);
	if (not impossible) {
		.print("**** Going to charge my battery at ", FacilityAux2);
		!goto(FacilityAux2);
		!charge;		
	}
	else {
		-impossible;
	}

	.
	
+!check_list_charging(List,FacilityId)
<-
	?closest_facility(List,FacilityId,Facility);
	?enough_battery_charging(Facility, Result);
	if (Result) {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,FacilityId);
	}
	.
	
//### RINGING ###
+!ringingFinished
	: not .desire(goto(_))
<-
	-myProposal(_);
	!free;
	.
+!ringingFinished
<-
	-myProposal(_);
	.
	
+!go_to_facility(Facility)
<-
	!goto(Facility);
	?step(S);
	.print("I have arrived at ", Facility, "   -   Step: ",S);
	.send(vehicle15,tell,doneExploration);
	!free;
	.
+!start_ringing
	: .my_name(Me) & shopList(List) & find_shops_id(List,[],ListOfShops)
<-
	.print("Starting Ringing");
	+numberAwarded(.length(List));

	!order_agents_to_go_to_the_shops(ListOfAgents);

	.delete(agents(Me),ListOfAgents,ListOfAgentsWithoutMe);
	
	!create_list_of_proposals(ListOfShops,ListOfProposals);
	
	!make_proposal(ListOfShops,ListOfProposals,ListOfAgentsWithoutMe,ListOfAgents);
	. 
+!create_list_of_proposals(ListOfShops, ListOfProposals)
<-
	+tempProposalsShopRing([]);	
	for (.member(Shop, ListOfShops)){
		?tempProposalsShopRing(InitialList);
		.concat(InitialList,[currentProposal(Shop,"ini1",100,"ini2",100)],NewList);	
		-+tempProposalsShopRing(NewList);
	}
	
	?tempProposalsShopRing(FinalList);	
	ListOfProposals = FinalList;
	-tempProposalsShopRing(FinalList);
	.

+!calculate_steps_required_all_shops
	: .my_name(Me) & role(Role, Speed, _, _, _) & shopList(List) & find_shops_id(List,[],ShopsList)
<- 	
	pucrs.agentcontest2016.actions.pathsToFacilities(Me, Role, Speed, ShopsList, Proposal);
	-+myProposal(Proposal);
	.
+!calculate_steps_required_all_shops
<- 	
	!calculate_steps_required_all_shops;
	.
	
+!sendAgentsToTheirShops
	: tempAgentsSendProposals(ListShopAgent)
<-
	for (.member(proposalAgent(Shop,Agent,_),ListShopAgent) ){
		.send(Agent,achieve,go_to_facility(Shop));
	}
	.

+!calculateBestShopToEachAgent
	: tempComparingProposals(Proposals)
<-
	-+tempAgentsSendProposals([]); 
	
	for (.member(currentProposal(Shop,FirstAgent,FirstSteps,SecondAgent,SecondSteps),Proposals) ){		
		
		?tempAgentsSendProposals(InitialList);
		
		if (.member(proposalAgent(ShopProposal,FirstAgent,WorstBetterSteps), InitialList) ){	
			if (FirstSteps > WorstBetterSteps){
				.difference(InitialList,[proposalAgent(ShopProposal,FirstAgent,WorstBetterSteps)],TempProposal);
				.concat(TempProposal,[proposalAgent(Shop,FirstAgent,FirstSteps)],NewProposals);	
				-+tempAgentsSendProposals(NewProposals);
			} 
		} else{
			.concat(InitialList,[proposalAgent(Shop,FirstAgent,FirstSteps)],NewProposals);	
			-+tempAgentsSendProposals(NewProposals);
		}
	}	
 	.
+!make_proposal(AvailableShops, Proposals, [], AvailableAgents)
	: .my_name(Me)
<-
	!calculate_steps_required_all_shops;
		
	!compare_proposals(AvailableShops, Proposals);
	
	!calculateBestShopToEachAgent;
	
	!sendAgentsToTheirShops;
	
	!find_out_the_remaing_agent_and_shops(AvailableShops, AvailableAgents);
	
	?tempNewListAvailableShops(NewAvailableShops);
	!create_list_of_proposals(NewAvailableShops, ListOfProposals);	
	
	?tempNextAgent(NextAgent);	
	?tempListAgentsRing(ListAgents);
	?tempNewListAvailableAgent(NewAvailableAgents);
	
	if (not .empty(NewAvailableShops)){
		.send(NextAgent,achieve,make_proposal(NewAvailableShops,ListOfProposals,ListAgents,NewAvailableAgents));
	} else{
		.print("Ringing is Done");
		.broadcast(achieve,ringingFinished);
		
		if(not .length(NewAvailableAgents, 0)) {
			.nth(0, NewAvailableAgents, agents(FreeAgent));
			.send(FreeAgent, tell, allowedToPostJobs);
		}
		!!free;			
	}	
	
	// Clean up
	-tempComparingProposals(_);	
	-tempAgentsSendProposals(_);
	-tempNewListAvailableAgent(_);
	-tempNewListAvailableShops(_);
	-tempNextAgent(_);
	-tempListAgentsRing(_);
	.

+!make_proposal(AvailableShops, Proposals, [agents(NextAgent)|RemainingAgents], AvailableAgents)
	: .my_name(Me)
<-
	!calculate_steps_required_all_shops;

	!compare_proposals(AvailableShops, Proposals);
	
	!send_proposal_next_agent(AvailableShops, NextAgent, RemainingAgents, AvailableAgents);
	
	-tempComparingProposals(_);	
	.
+!compare_proposals(AvailableShops, Proposals)
	: .my_name(Me) & myProposal(MyProposal)
<-
	-+tempComparingProposals([]);	
	
	for (.member(proposal(_,Shop,MeSteps), MyProposal)){	
		ShopBusca = Shop;
		if (.member(currentProposal(Shop,FirstAgent,FirstSteps,SecondAgent,SecondSteps),Proposals) ){		
			if (MeSteps < FirstSteps){
				RetSecondAgent 	= FirstAgent;
				RetSecondSteps 	= FirstSteps;
				RetFirstAgent 	= Me;
				RetFirstSteps 	= MeSteps;
			} else{
				if (MeSteps < SecondSteps){
					RetSecondAgent 	= Me;
					RetSecondSteps 	= MeSteps;
					RetFirstAgent 	= FirstAgent;
					RetFirstSteps 	= FirstSteps;
				} else{
					RetSecondAgent 	= SecondAgent;
					RetSecondSteps 	= SecondSteps;
					RetFirstAgent 	= FirstAgent;
					RetFirstSteps 	= FirstSteps;
				}
			}
			
			?tempComparingProposals(InitialList);
			.concat(InitialList,[currentProposal(Shop,RetFirstAgent,RetFirstSteps,RetSecondAgent,RetSecondSteps)],NewProposals);
			-+tempComparingProposals(NewProposals);
		} 
	}
	
	?tempComparingProposals(LastProposals);
	.

+!find_out_the_remaing_agent_and_shops(AvailableShops, AvailableAgents)
	: tempAgentsSendProposals(ListShopAgent)
<-
	+tempNewListAvailableAgent(AvailableAgents);
	+tempNewListAvailableShops(AvailableShops);
	
	for(.member(proposalAgent(Shop,Agent,_),ListShopAgent)){		
		?tempNewListAvailableAgent(A);		
		.delete(agents(Agent),A,NewA);	
		-+tempNewListAvailableAgent(NewA);			
		
		?tempNewListAvailableShops(S);
		.delete(Shop,S,NewS);
		-+tempNewListAvailableShops(NewS);		
	}
	
	?tempNewListAvailableAgent([agents(Next)|Tail]);
	-+tempNextAgent(Next);
	-+tempListAgentsRing(Tail);
	.
+!send_proposal_next_agent(AvailableShops, NextAgent, RemainingAgents, AvailableAgents)
	: tempComparingProposals(Proposals)
<-
	.send(NextAgent,achieve,make_proposal(AvailableShops, Proposals, RemainingAgents, AvailableAgents));
	.
+!order_agents_to_go_to_the_shops(ListOfAgents)
	: not initiatorShopChoice
<-	
	ListOfAgents = [agents(vehicle1),agents(vehicle2),agents(vehicle3),agents(vehicle4),agents(vehicle5),agents(vehicle6),agents(vehicle7),agents(vehicle8),agents(vehicle9),agents(vehicle10),agents(vehicle11),agents(vehicle12),agents(vehicle13),agents(vehicle14),agents(vehicle15),agents(vehicle16)];
	.	
//### RINGING ###

+!free 
  : allowedToPostJobs & (explorationInProgress | goHorse) & storageList(StorageList) & (not .desire(goto(_)) & not .desire(charge)) 
<-    
  // Populate itemList with product list (to easy access)
  +itemList([]); 
  for ( product(ItemId,Volume,BaseList) ) { 
    ?itemList(List); 
    -+itemList([ItemId|List]); 
  } 
  ?itemList(ItemList);  
  // Shuffle list to get some random items
  .shuffle(ItemList, ShuffledItemList);
  +randomItems([]);
  // We will get (length / 3) + 1 items to this job
  NumberOfItems = math.floor(.length(ShuffledItemList) / 3) + 1;
  for (.range(I,0,NumberOfItems)) {
  	// Get nth item
  	.nth(I, ShuffledItemList, TempItemId);
  	?randomItems(TempList); 
  	?product(TempItemId, Volume, _);
  	// Select the number of items to be posted (between 600 and 900, so only a truck will be able to do it with one trip), and dividing this by this item volume.
  	N = math.ceil(math.ceil(600 + math.random(300)) / Volume);
  	-+randomItems([item(TempItemId,N)|TempList]);
  }
  ?randomItems(ItemsToBePosted);
  // Get random storage
  .nth(math.floor(math.random(.length(StorageList))), StorageList, StorageId);
  // Decide if we are going to post an auction or a priced job, with the random product selected 
  .random(N); 
  if(N < 0.5) { 
    // Posting auction job (MaxBid, Fine, JobActive, AuctionActive, StorageId, Items)
    if (goHorse) {
    	!post_job_auction(1000, 1, 20, 5, StorageId, ItemsToBePosted); 
    }
    else {
    	!post_job_auction(1000, 1, 20, 100, StorageId, ItemsToBePosted); 
    }
  } else { 
    // Posting priced job (Reward, JobActive, StorageId, Items)
    !post_job_priced(1, 20, StorageId, ItemsToBePosted); 
  } 
  -itemList(_); 
  -randomNumberOfItems(_); 
  -randomItems(_);
  !free.
  
+!free
	: not goHorse & (not .desire(goto(_)) & not .desire(charge)) & load(Load) & Load \== 0
<-
	!go_dump;
	!free;
	.
+!free
	: not .desire(goto(_)) & not .desire(charge)
<-
	!skip;
	!free;
	.