@postAuctionJobAlt
+!select_goal
	: post_job_auction(MaxBid, Fine, JobActive, AuctionActive, StorageId, Items)
<-
	!post_job_auction(MaxBid, Fine, JobActive, AuctionActive, StorageId, Items);
	.print("Posted an auction job.");
	.
	
@postPricedJobAlt
+!select_goal
	: post_job_priced(Reward, JobActive, StorageId, Items)
<-
	!post_job_priced(Reward, JobActive, StorageId, Items);
	.print("Posted a priced job.");
	.	

@buyAction
+!select_goal
	: buyList(ItemId,Qty,Shop) & inFacility(Shop) & shop(Shop,Lat,Lon,Items) & .member(item(ItemId,Price,Qty2,Restock),Items) & Qty2 > Qty
<-
	!buy(ItemId,Qty);
	.print("Buying ",Qty,"x item ",ItemId, " in shop ",Shop);
	.
	
@buyActionSkip
+!select_goal
	: buyList(Item,Qty,Shop) & inFacility(Shop) & shop(Shop,Lat,Lon,Items) & .member(item(Item,Price,Qty2,Restock),Items) & Qty2 < Qty
<-
	!skip;
	.print("Not enough items on the shop, skipping my action to try again next step.");
	.
	
@assembleItem
+!select_goal 
	: assembleList(ItemId,Workshop) & inFacility(Workshop) //& verify_items(Bases) 
<- 
	!assemble(ItemId);
	.print("Assembling item ", ItemId, " in workshop ", Workshop);		
	.	

@remember
+!select_goal
	: remember(Facility)
<- 
	-remember(Facility);
	!goto(Facility);
	.print("Initiating go to again to ",Facility);
	.

@continueGotoFacility
+!select_goal 
	: going(Facility)
<-
	!continue;
	.print("Continuing to location ",Facility);
	.

@gotoShop
+!select_goal
	: buyList(Item,Qty,Shop) & not going(_)
<-
	!goto(Shop);
	.print("Going to ",Shop);
	.
	
@gotoWorkshop
+!select_goal
	: assembleList(Item,Workshop) & not going(_) & not buyList(_,_,_) //& compositeMaterials(CompositeList) & .intersection(ListAssemble,CompositeList,Inter) & verify_tools(Inter,[],ToolsMissing)
<-
//	if (ToolsMissing \== [])
//	{
//		?serverName(Name);
//	    for (.member(assemble(ItemId,Tool),ToolsMissing))
//	    {
//	  		?count(ItemId,ListAssemble,0,Qty);
//	  		+waitingForAssistAssemble(ItemId,Qty,Tool,Facility,Name);  		
//	    }
//	    .nth(0,ToolsMissing,assemble(ItemId2,Tool2));
//	    ?count(ItemId2,ListAssemble,0,Qty2);
// 		.print("I need help assembling ",Qty2,"x: ",ItemId2, " with ",Tool2," in ",Facility);
// 		.broadcast(tell,helpAssemble(ItemId2,Qty2,Tool2,Facility,Name));	
//	}
	!goto(Workshop);
	.print("Going to workshop ", Workshop);
	.	

// Default action is to skip
@skipAction
+!select_goal
	: true
<-
	!skip;
	.print("Nothing to do at this step");
	.

/* 
@abort
+!select_goal
	: going(Facility) & abort
<-
	.print("Aborting goto action to help, agent does not need my help anymore.");
	-abort;
	-going(Facility);
	!abort;
	.

@postBid
+!select_goal
	: bid(JobId,Bid,Items,StorageId,MaxBid) & not postedBid(JobId) & going(Facility)
<-
	!bid_for_job(JobId,Bid);
	.print("Had to stop to post bid ",Bid," for job: ",JobId," which had max bid of ",MaxBid);
	+auctionJob(JobId,Items,StorageId);
	+postedBid(JobId);
	+remember(Facility);
	.

@postBidAlt
+!select_goal
	: bid(JobId,Bid,Items,StorageId,MaxBid) & not postedBid(JobId)
<-
	!bid_for_job(JobId,Bid);
	.print("Posted bid ",Bid," for job: ",JobId," which had max bid of ",MaxBid);
	+auctionJob(JobId,Items,StorageId);
	+postedBid(JobId);
	.

@chargeAction
+!select_goal 
	: low_battery & inFacility(Facility) & chargingList(List) & .member(Facility,List) & not charging  
<- 
	.print("Began charging.");
	!charge;
	. 

@deliverJob
+!select_goal 
	: working(JobId,Items,StorageId) & inFacility(StorageId) & verify_items(Items) & loadExpected(LoadE)
<- 
	!deliver_job(JobId);
	-working(JobId,Items,StorageId);
	.print("Job ", JobId, " has been delivered.");
	+countAux(0);
	for ( .member(item(ItemId,Qty),Items))  {
		?product(ItemId,Volume,BaseList);
		-item(ItemId,Qty);
		+item(ItemId,0);
		?countAux(X);
		-+countAux(X + Qty * Volume);
	}
	?countAux(X);
	-countAux(X);
	-+loadExpected(LoadE-X);
	.
	
@storeItem
+!select_goal 
	: false & inFacility(Facility) & storageList(List) & .member(Facility,List) & storeList([item(ItemId,Qty)|Items])
<- 
	!store(ItemId,Qty);
	?item(IdemId,Qty2);
	-item(ItemId,Qty2);
	+item(ItemId,Qty2-Qty);
	-+storeList(Items);
	.
	
@retrieveItem
+!select_goal 	
	: false & inFacility(Facility) & storageList(List) & .member(Facility,List) & retrieveList([item(ItemId,Qty)|Items])
<- 
	!retrieve(ItemId,Qty);
	?item(IdemId,Qty2);
	-item(ItemId,Qty2);
	+item(ItemId,Qty2+Qty);
	-+retrieveList(Items);	
	.	
	
@retrieveDeliveredPartial
+!select_goal 	
	: false & partial(JobId,[item(ItemId,Qty)|Items],StorageId) & inFacility(StorageId)
<- 
	!retrieve_delivered(ItemId,Qty);
	?item(IdemId,Qty2);
	-item(ItemId,Qty2);
	+item(ItemId,Qty2+Qty);
	-+partial(JobId,Items,StorageId);
	.	
	
@retrieveDeliveredJob
+!select_goal 	
	: false & delivered(JobId,[item(ItemId,Qty)|Items],StorageId) & inFacility(StorageId)
<- 
	!retrieve_delivered(ItemId,Qty);
	?item(IdemId,Qty2);
	-item(ItemId,Qty2);
	+item(ItemId,Qty2+Qty);
	-+delivered(JobId,Items,StorageId);
	.		
	
@assistAssemble
+!select_goal
	: helpAssemble(ItemId,Qty,Tool,Facility,Agent) & inFacility(Facility)
<-
	.print("I am assisting agent ",Agent," in order to make ",Qty,"x of item ",ItemId);
	!assist_assemble(Agent);
	.

@assembleItemWithAssist
+!select_goal 
	: assembleList([ItemId|ListAssemble]) & inFacility(Facility) & workshopList(ListWorkshop) & .member(Facility,ListWorkshop) & product(ItemId,Volume,Bases) & iAmHere(ItemId,_,Tool,FacilityHelp,Agent)
<- 
	.print("Assembling, with assist, item ", ItemId, " in workshop ", Facility);	
	!assemble(ItemId);
	-+assembleList(ListAssemble);
	?item(ItemId,Qty);
	-item(ItemId,Qty);
	+item(ItemId,Qty+1);
	for (.member(consumed(ItemIdBase,QtyBase),Bases))  {
		?item(ItemIdBase,Qty2);
		-item(ItemIdBase,Qty2);
		+item(ItemIdBase,Qty2-QtyBase);
	};
	.

@continueCharging
+!select_goal 
	: charging //& charge(Battery) & chargeTotal(BatteryCap) & Battery < BatteryCap
<- 
	.print("Keep charging."); 
	!continue;
	.
	
@gotoCharging	
+!select_goal 
	: low_battery & chargingList(List) & closest_facility(List,Facility) 
<- 
	.print("Going to charging station ",Facility);
	if (going(Facility))
	{
		+remember(Facility);
	} 
	!goto(Facility);
	.		
	
@continueGotoLatLon
+!select_goal 
	: going(Lat,Lon)
<-
	.print("Continuing to latitude ",Lat," and longitude ",Lon); 
	!continue;
	.		
	
@waitingForAssistAssemble
+!select_goal
	: waitingForAssistAssemble(ItemId,Qty,Tool,Facility,Name)
<-
	.print("I am waiting for help to assemble some items.");
	.broadcast(tell,helpAssemble(ItemId,Qty,Tool,Facility,Name));	
	!skip;	
	.
	
@gotoWorkshopToAssist
+!select_goal
	: helpAssemble(ItemId,Qty,Tool,Facility,Agent)
<-
	.print("I'm going to workshop ", Facility, " to assist agent ",Agent," in order to make ",Qty,"x of item ",ItemId);
	!goto(Facility);	
	.	

@gotoStorageToDeliverJob
+!select_goal
	: working(JobId,Items,StorageId) & verify_items(Items) & not going(_) & not buyList(_,_,_) & baseListJob(Bases) & auxList(Aux)
<-
	.print("I have all items for job ",JobId,", now I'm going to deliver the job at ", StorageId);
	// let agents know you do not need help anymore
	for (iAmHere(ItemId,Qty,Tool,FacilityHelp,Agent)[source(X)])
	{
		-iAmHere(ItemId,Qty,Tool,FacilityHelp,Agent)[source(X)];
		.send(X,untell,helpAssemble(ItemId,Qty,Tool,FacilityHelp,Agent));
	}
	for (iAmGoing(ItemId2,Qty2,Tool2,FacilityHelp2,Agent2)[source(X)])
	{
		-iAmGoing(ItemId2,Qty2,Tool2,FacilityHelp2,Agent2)[source(X)];
		.send(X,untell,helpAssemble(ItemId,Qty,Tool,FacilityHelp,Agent));
	}
	// clearing bases used to assemble
	-baseListJob(_);
	-auxList(_);
	+auxList([]);
	!goto(StorageId);
	.

// Give item to other agent
// TODO: message
+!select_goal
    : false & inFacility(dump1) & hasToGive(ItemId, Qty)
<-
    .print("I am giving item ", ItemId, "(", Qty, ") to agent a4");
    !give(a4, ItemId, Qty);
    ?item(ItemId, NewQty);
    if(NewQty < Qty){
    	-hasToGive(ItemId, Qty)
    }
	.

// Receive item from other agent
// TODO: message
+!select_goal
    : false & inFacility(dump1) & hasToReceive(ItemId, Qty)
<-
    .print("I am retrieving item ", ItemId, "(", Qty, ") from agent a1");
    !receive;
    ?item(ItemId, NewQty);
    if(NewQty > Qty){
    	-hasToReceive(ItemId, Qty)
    }
	.

// Giver goto meeting place
+!select_goal
    : false & not going(_) & roled("Car", _, _, _, _) & item(ItemId, Qty) & Qty > 0
<-
    //.print(">>>>>>>>> I am going to ", FacilityId, " to give/retrieve item(", ItemId, Qty, ") to agent ", AgentId);
    .print("I am going to ", dump1, " to give/retrieve item(", ItemId, Qty, ") to agent ?");
    //!goto(FacilityId);
    +hasToGive(ItemId, Qty);
    !goto(dump1);
	.

// Receiver goto meeting place
+!select_goal
    : false & not going(_) & roled("Truck", _, _, _, _) & item(ItemId, Qty) & Qty > 0
<-
    //.print(">>>>>>>>> I am going to ", FacilityId, " to give/retrieve item(", ItemId, Qty, ") to agent ", AgentId);
    .print("I am going to ", dump1, " to give/retrieve item(", ItemId, Qty, ") to agent ?");
    //!goto(FacilityId);
    +hasToReceive(ItemId, Qty);
    !goto(dump1);
	.

// Dump if in facility, not working and have any item different from a tool
+!select_goal
	: false & item(ItemId,Qty) & Qty > 0 & not is_tool(ItemId) & inFacility(DumpId) & dumpList(DumpList) & .member(DumpId,DumpList)
<- 
	.print("Dumping ", ItemId, "(", Qty, ")");
	!dump(ItemId, Qty);
	-item(ItemId, Qty);
	.

// Goto dump facility if not working and have any item different from a tool
+!select_goal
	: false & free & item(ItemId,Qty) & Qty > 0 & not is_tool(ItemId) & dumpList(DumpList) & not working(_,_,_)
<-
	?closest_facility(DumpList, DumpId);
	.print("I am going to ", DumpId);
	!goto(DumpId);
	.
*/