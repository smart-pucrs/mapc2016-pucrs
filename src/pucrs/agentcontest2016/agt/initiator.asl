calculateCost([],Aux,Cost) :- Cost = Aux.
calculateCost([item(Id,Qty)|List],Aux,Cost) :-.term2string(Id,IdS)  & itemPrice(IdS,Price) & calculateCost(List,Aux+Price*Qty,Cost).

+step(1)
	: shopList(List)
<-
	-+jobsInProgress(0); 
	
	for ( product(ItemId,_,BaseList) ) {
		if (not .empty(BaseList)) {
			?find_shops(ItemId,List,ShopsViable);
			if (not .empty(ShopsViable)) {
				?assembledInShops(ItemsAsb);
				-assembledInShops(ItemsAsb);
				.concat(ItemsAsb,[ItemId],NewList);
				+assembledInShops(NewList);
			}
		}
	}
	?find_shops_id(List,[],List2);
	?map_center(CenterLat, CenterLon);
	?closest_facility_from_center(CenterLat, CenterLon, List2, ShopId);
	+center_shop(ShopId);
	.broadcast(tell,explorationInProgress); 
	.

+!create_taskboard
	: true
<-
	makeArtifact("task_board","pucrs.agentcontest2016.cnp.TaskBoard",[]);
	.print("Created taskboard.");
	.

// check if it can start considering jobs again
@done[atomic]
+done(JobId)[source(X)]
	: jobsInProgress(NumberJobsProgress) & numberAwarded(JobId,NumberAgents) & .count(done(JobId)[source(_)], NumberDone) & NumberAgents == NumberDone & pricedJob(JobId, Items, StorageId)
<-
	-+jobsInProgress(NumberJobsProgress-1);
	.print("## We Have ",NumberJobsProgress-1," Jobs In Progress Right Now! One Job (",JobId,") is Done");
	
	-pricedJob(JobId, Items, StorageId);
	?agentsFree(AFree);
	-+agentsFree(AFree + 1);
	-numberAwarded(JobId,NumberAgents);
	for ( done(JobId)[source(A)] ) {
		-done(JobId)[source(A)];
	}
	.print("All agents are done, time to start looking for a new job.");
	.
	
@done2[atomic]
+done(JobId)[source(X)]
<-
	?agentsFree(AFree);
	-+agentsFree(AFree + 1);
	.print(X, " has finished its task (",JobId,"), waiting for the rest to be done.");
	.
	
@done5[atomic]
+doneExploration[source(X)]
	: numberAwarded(NumberAgents) & .count(doneExploration[source(_)], NumberDone) & NumberAgents == NumberDone
<-
	-shopExplorationInProgess;
	.print("## Shop Exploration Finished");
	addPrices;
	-numberAwarded(NumberAgents);
	for ( doneExploration[source(A)] ) {
		-doneExploration[source(A)];
	}
	.broadcast(untell,explorationInProgress); 
	.print("All agents are done, time to start looking for a new job.");
	.	
@done6[atomic]
+doneExploration[source(X)]
<-
	.print(X, " has finished its shop exploration, waiting for the rest to be done.");
	.
	
//// AQUI SE DEFINE MAXIMO DE JOBS SERAO FEITOS POR VEZ
+pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)]
	: jobsInProgress(NumberJobsProgress) & (NumberJobsProgress == 3)
<-
	.print("## We've already reached our maximum number of simultaneous jobs");
	-pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)];
 	.
@pricedJob[atomic]
+pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)]
	: not goHorse & not shopExplorationInProgess & not pricedJob(JobId,Items,StorageId) & not cnp(_) & step(Step) & center_shop(ShopId) & chargingPrice(PriceC,Rate) & agentsFree(AFree)
<- 
	.broadcast(achieve,notFree(Step));
	.print("New priced job: ",JobId," Items: ",Items, " Storage: ", StorageId," started at ",Begin," ends at ",End," and rewards ",Reward);
	.length(Items,NumberTasks);
	if ( NumberTasks <= AFree) {
		+doable(0);
		?assembledInShops(Assembled);
		for ( .member(item(ItemId,Qty),Items) ) {
			?product(ItemId,Volume,BaseList);
			if (.empty(BaseList) | .substring(ItemId,Assembled)) {
				?doable(NDo);
				-+doable(NDo+1);
			}
		}
    	?doable(NumberDo); 
    	-doable(NumberDo); 
    	.print("Number of doable items: ", NumberDo," out of ",NumberTasks); 
    	if (NumberDo == NumberTasks) { 
    		?map_center(CenterLat, CenterLon);
			?route_car_from_center(CenterLat, CenterLon, ShopId, RouteLenShop);
			?route_car_from_center(CenterLat, CenterLon, StorageId, RouteLenStorage);
			Total = math.round( (RouteLenShop/3 + RouteLenStorage/3) * NumberTasks );
			.print("We estimate ",Total+35," steps to do priced job ",JobId," that needs ",End-Step," steps");
			if (Total+35 >  End-Step) {
				.print("Ignoring priced job ",JobId," even in the best case scenario we would not be able to complete it.");
				.broadcast(achieve,endCNP);
			}
			else {
				BatteryFee = math.round((((RouteLenShop / 3 * 10) * NumberTasks) + ((RouteLenStorage / 3 * 10) * NumberTasks)) / Rate) * (PriceC*Rate);
				.print("Battery fee ",BatteryFee);
				?calculateCost(Items,0,Cost);
				.print("Reward for this job is ",Reward," and we estimate the approximate cost is ",Cost+BatteryFee);
				if (Cost+BatteryFee < Reward) {
					.print("Job is viable and profitable, starting contract net.");
					+numberTasks(NumberTasks);
					!separate_tasks(Items,JobId,StorageId);
				}
				else {
					.print("Bad job, it could cost more than the reward.");
					.broadcast(achieve,endCNP);
					-pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)];
				}
			}
		}
		else {
			.print("Composite items detected, ignoring job.");
			.broadcast(achieve,endCNP);
			-pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)];
		}
	}
	else {
		.print("Too many tasks, not enough agents!");
		.broadcast(achieve,endCNP);
		-pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)];
	}
	.
+pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)]
<-
	.print("Job dumped!");
	-pricedJob(JobId, StorageId, Begin, End, Reward, Items)[source(X)];
	.
	
// Calculate map center, based on shop locations. 
// This adds a belief of "map_center", so future calls to ?map_center(CenterLat, CenterLon) will not need to perform this code again.
@map_center[atomic]
+?map_center(CenterLat, CenterLon)
	: shopList(ShopList)
<-
	// These two lists will store respectively latitude and longitude locations of shops
	-+shopLatitudes([]);
	-+shopLongitudes([]);
	for( .member(shop(ShopId,_),ShopList) ) {
		pucrs.agentcontest2016.actions.getLocation(ShopId, ShopLat, ShopLon);
		?shopLatitudes(LatList);
		?shopLongitudes(LonList);
		-+shopLatitudes([ShopLat | LatList]);
		-+shopLongitudes([ShopLon | LonList]);
	}
	// Add a belief that the center of the map is in the average of the shops locations.
	?shopLatitudes(LatList);
	?shopLongitudes(LonList);
	CenterLat = math.average(LatList);
	CenterLon = math.average(LonList);
	-+map_center(CenterLat, CenterLon);
	-shopLatitudes(_);
	-shopLongitudes(_);
	.

@count_composite[atomic]
+!count_composite(ItemId,Qty,BaseList)
	: true 
<- 
	if (BaseList \== []) {
		for ( .range(I,1,Qty) ) {
			?count_comp(NumberOfComp);
			-+count_comp(NumberOfComp+1);			
			for ( .member(consumed(ItemId2,Qty2),BaseList) ) {
				?product(ItemId2,Volume2,BaseList2);
				!count_composite(ItemId2,Qty2,BaseList2);
			}
		}
	}
	.
	
+!separate_tasks(Items,JobId,StorageId)
	: max_bid_time(Time)
<-
	for ( .member(item(ItemId,Qty),Items) ) {
		!!allocate_task(item(ItemId,Qty),Time,Items,JobId,StorageId);
	}
	.
	
+!allocate_task(item(ItemId,Qty),Timeout,Items,JobId,StorageId)
	: true
<- 
	announce(item(ItemId,Qty),Timeout,StorageId,CNPBoardName);
	+cnp(CNPBoardName);
	.print("Announced: ",Qty,"x of ",ItemId," on ",CNPBoardName);
	getBids(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
		+pricedJob(JobId,Items,StorageId);
		.print("Got bids (",.length(Bids),") for task ",CNPBoardName," List ",Bids);
		!select_bid(Bids,JobId,StorageId);
	}
	else {
		.print("No bids.");
	}
	-cnp(CNPBoardName);
	clear(CNPBoardName);
	.

@select_bid[atomic]
+!select_bid(Bids,JobId,StorageId)
	: numberTasks(NumberTasks)
<-
	if (not allBids(_)) {
		+allBids([Bids]);
		if (1 == NumberTasks) {
	    	.print("Complete bid list ",BidList);
	    	-allBids(_);
	    	?select_bid(Bids,bid(99999,99999,99999,99999),bid(Bid,Agent,ShopId,item(ItemId,Qty)));
			.print("Bid that won: ",Bid," Agent: ",Agent," going to ",ShopId);
			.send(Agent,tell,winner(item(ItemId,Qty),JobId,StorageId,ShopId));
			.broadcast(achieve,endCNP);
    	}
	}
	else {
		?allBids(AuxBidList);
		.concat(AuxBidList,[Bids],BidList);
		-+allBids(BidList);
		 ?allBids(BidList);
	    if (.length(BidList) == NumberTasks) {
	    	.print("Complete bid list ",BidList);
	    	-allBids(_);
	    	for (.range(I,0,.length(BidList)-1)) {
	    		.nth(I,BidList,X);
		    	?select_bid(X,bid(99999,99999,99999,99999),bid(Bid,Agent,ShopId,item(ItemId,Qty)));
		    	.print("Bid that won: ",Bid," Agent: ",Agent," going to ",ShopId);
		    	if (not awarded(Agent,_,_)) {
		    		+awarded(Agent,ShopId,[item(ItemId,Qty)]);
		    		.term2string(Agent,AgentS);
		    		?load(AgentS,Load);
		    		?product(ItemId,Volume,BaseList);
		    		updateLoad(Agent,Load-Volume*Qty);
		    	}
		    	else {
		    		?awarded(Agent,ShopId,List);
		    		-awarded(Agent,ShopId,List);
		    		.concat(List,[item(ItemId,Qty)],NewList);
		    		+awarded(Agent,ShopId,NewList);
		    		.term2string(Agent,AgentS);
					?load(AgentS,Load);
		    		?product(ItemId,Volume,BaseList);
		    		updateLoad(Agent,Load-Volume*Qty);		    		
		    	}
		    }
		    .count(awarded(_,_,_),N);
		    +numberAwarded(JobId,N);
		    -numberTasks(NumberTasks);
		    ?agentsFree(AFree);
		    -+agentsFree(AFree-N);
		    for (awarded(Agent,ShopId,List)) {
		    	.print("Agent ",Agent," to get ",List," in ",ShopId);
		    	.send(Agent,tell,winner(List,JobId,StorageId,ShopId));
    			-awarded(Agent,ShopId,List);	
			}			
			.broadcast(achieve,endCNP);
			?jobsInProgress(NumberJobsProgress);
			-+jobsInProgress(NumberJobsProgress+1);
			.print("## We Have ",NumberJobsProgress+1," Jobs (",JobId,") In Progress Right Now!");
	    }
	}
	.