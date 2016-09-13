//+visibleChargingStation(_,_,_,_,_,_,Slots)
//<- .print("Slots occupied: ",Slots).
//+charge(Battery)
//<- .print("My battery: ",Battery).
//+lastAction(Action)
//	: lastActionReal(ActionReal)
//<-
//	.print("Did ",ActionReal," server said ",Action);
//	.
+lastAction(Action)
	: Action == noAction & lastActionReal(ActionReal) & noActionCount(Count)
<-
	-+noActionCount(Count+1);
	.print(">>>>>>>>>>> I have done ",Count+1," noActions.");
	!commitAction(ActionReal);
	.
+lastAction(Action)
	: Action == noAction & noActionCount(Count)
<-
	-+noActionCount(Count+1);
	.print(">>>>>>>>>>> I have done ",Count+1," noActions.");
	.
	
//+lastActionResult(Result)
//	: Result == failed_random & lastActionReal(Action) & .substring("deliver_job",Action)
//<-
//	.print("Deliver Job failed, executing it again.");
//	.drop_desire(free);
//	!commitAction(Action);
//	!free;
//	.

+simEnd
	: .my_name(Me)
<-
	!end_round;
	setMap;
	.wait(500);
	if (Me == vehicle15) {
		+working;
		+max_bid_time(1000);
		+chargingPrice(0,0);
		+assembledInShops([]);
		+shopExplorationInProgess;
	}
	!new_round;
	!start;
	.

+inFacility(Facility)
	: going(Facility)
<-
	-going(Facility);
	.
	
//+buyList(ItemId,Qty,ShopId)
//<-
//	.print("Added buylist to buy #",Qty," of ",ItemId," at ",ShopId).
	
+item(ItemId,Qty)
	: buyList(ItemId,Qty,ShopId)
<-
	-buyList(ItemId,Qty,ShopId);
//	.print("I have confirmation that I have bought the item sucessfuly: ",ItemId);
	.

+lastActionResult(Result)
	: Result == failed_random & lastActionReal(Action) & step(Step)
<-
	.print("Failed to execute action ",Action," on step ",Step-1," due to the 1% random error.");
	.
	
@shopList[atomic]
+shop(ShopId, Lat, Lng, Items)
	: shopList(List) & not .member(shop(ShopId,_),List)
<-
	-+shopList([shop(ShopId,Items)|List]);
	.
			
@storageList[atomic]
+storage(StorageId, Lat, Lng, Price, TotCap, UsedCap, Items)
	: storageList(List) & not .member(StorageId,List)
<-
	-+storageList([StorageId|List]);
	.	

@chargingListv1[atomic]
+chargingStation(ChargingId,Lat,Lng,Rate,Price,Slots) 
	:  chargingList(List) & not .member(ChargingId,List) & .my_name(Me) & Me == vehicle15 & chargingPrice(Price2,Rate2)
<-
	if (Price*Rate > Price2*Rate2) {
		-+chargingPrice(Price,Rate);
	}	
	-+chargingList([ChargingId|List]);
	.
@chargingList[atomic]
+chargingStation(ChargingId,Lat,Lng,Rate,Price,Slots) 
	:  chargingList(List) & not .member(ChargingId,List)
<-
	-+chargingList([ChargingId|List]);
	.

	
@workshopList[atomic]
+workshop(WorkshopId,Lat,Lng,Price) 
	:  workshopList(List) & not .member(WorkshopId,List)  //& workshopPrice(Price2)
<- 
//	if (Price > Price2)
//	{
//		-+workshopPrice(Price);
//	}
	-+workshopList([WorkshopId|List]);
	.

@dumpList[atomic]
+dump(DumpId,Lat,Lng,Price) 
	:  dumpList(List) & not .member(DumpId,List) 
<- 
	-+dumpList([DumpId|List]);
	.
	
+!notFree(Step2)
//: step(Step1) & Step1 == Step2
<-
//	.print("Not free, step ",Step2);
	.drop_desire(free);
.
//+!notFree(Step)
//<-
//	.wait({ +step(Step) });
//	!notFree(Step);
//	.
	
+!endCNP
: not winner(_,_,_,_)
<-
//	.print("Bid finished.");
	!free;
.
+!endCNP.

@decomp
+!decomp(Items)
	: true
<-
	+baseListJob([]);
	for ( .member(item(ItemId,Qty),Items) )
	{
		?product(ItemId,Volume,BaseList);
		!decomp_2(ItemId,Qty,BaseList);
	}
	for ( .member(consumed(ItemId,Qty),Items) )
	{
		?product(ItemId,Volume,BaseList);
		!decomp_2(ItemId,Qty,BaseList);
	}
	.
	
@decomp2
+!decomp_2(ItemId,Qty,BaseList)
	: true 
<- 
	if (BaseList == []) {
			?baseListJob(List2);
			-+baseListJob([item(ItemId,Qty)|List2]);
	} else {
//			for ( .range(I,1,Qty) ) {
//				?assembleList(ListAssemble);
//				-+assembleList([ItemId|ListAssemble]);				
			for ( .member(consumed(ItemId2,Qty2),BaseList) )
			{
				?product(ItemId2,Volume2,BaseList2);
//				if (BaseList2 \== [])
//				{
//					?auxList(Aux);
//					-+auxList([item(ItemId2,Qty2)|Aux]);						
//				}
				!decomp_2(ItemId2,Qty2,BaseList2);
			}
//			}
	}
	.

+!find_tools
	: role(_, _, _, _, Tools) & shopList(List)
<-
	for ( .member(Tool,Tools) )
	{
		?product(Tool,Volume,BaseList);
		if (BaseList == [])
		{
//			?find_shops(Tool,List,[Shop|Result]);
			//?best_shop(Result,Shop);
			+buyList(Tool,1,shop1);
		}
/* 		else
		{
			.print("Decomposing tool ",Tool);
			!decomp(BaseList);
			?baseListJob(Items);
			-baseListJob(_);
			for ( .member(item(ItemId,Qty),Items) )
			{
				?find_shops(ItemId,List,Result);
				?best_shop(Result,Shop);
				if (buyList(ItemId,Qty2,Shop))
				{
					-buyList(ItemId,Qty2,Shop);
					+buyList(ItemId,Qty+Qty2,Shop);			
				} else {
					+buyList(ItemId,Qty,Shop);		
				}	
			}
			?workshopList(WList);
			?closest_facility(WList, Workshop);
			+assembleList(Tool,Workshop);
		}*/
	}
	.
	
@goHorse[atomic]	
+step(Step)
	: steps(TotalSteps) & Step >= TotalSteps - 100 & not goHorse
<-
	+goHorse;
	.print("|||GO-HORSE|||");
	.
/* 
@suspend[atomic]
+!suspend
	: suspendList(List)
<-
	for ( .intend(Goal[Annotation]) )
	{
		if ( .sublist([Goal],List) )
		{
			+suspended(Goal);
			.suspend(Goal);
		}
	}.
	
@resume[atomic]
+!resume
<-
	for ( suspended(Goal) )
	{
		-suspended(Goal);
		.resume(Goal);
	}.
	
+charge(Battery)
	: charging & chargeTotal(BatteryTotal) & BatteryTotal == Battery
<-
	.print("Stop charging, battery is full.");
	-charging;
	.
	
+lastAction(Action)
	: Action \== skip & free
<-
	.print("I am not free anymore.");
	-free;
	.

+lastAction(Action)
	: Action == skip & not free
<-
	.print("I am free.");
	+free;
	.	

@helpAssemble[atomic]
+helpAssemble(ItemId,Qty,Tool,Facility,Agent)[source(X)]
	: item(Tool,1) & free & not working(_,_,_) & not helping
<-
	+helping;
	+warnAgent;
	.send(X,tell,iAmGoing(ItemId,Qty,Tool,Facility,Agent));
	.print("I can help, I have ",Tool);
	.

+helpAssemble(ItemId,Qty,Tool,Facility,Agent)[source(X)]
	: true
<-
	-helpAssemble(ItemId,Qty,Tool,Facility,Agent)[source(X)];
	.

-helpAssemble(ItemId,Qty,Tool,Facility,Agent)[source(X)]
	: helping & going(Facility)
<-
	for (helpAssemble(_,_,_,_,_)[source(X)])
	{
		-helpAssemble(_,_,_,_,_)[source(X)];
	}
	+abort;
	-helping;
	.	
	
-helpAssemble(ItemId,Qty,Tool,Facility,Agent)[source(X)]
	: helping
<-
	-helping;
	.		
	
+iAmHere(ItemId,Qty,Tool,FacilityHelp,Agent)[source(X)]
	: true
<-	
	-waitingForAssistAssemble(ItemId,Qty,Tool,FacilityHelp,Agent);
	.
	
+shop(ShopId, Lat, Lng, Items)
	: items_has_price(Items) & roled(Role, _, _, _, _) & Role \== "Truck" // this could be optimized
<-  
	for(.member(item(NItem,Price,Qty,Load),Items))
	{
		?item_qty(ShopId, NItem, Qty2);
		if (Qty2 \== Qty)
		{
			-item_qty(ShopId, NItem, Qty2);
			+item_qty(ShopId, NItem, Qty);
		}
	}
	.
	
+shop(ShopId, Lat, Lng, Items)
	: items_has_price(Items) & roled(Role, _, _, _, _) & Role == "Truck" // this could be optimized
<-  
	for(.member(item(NItem,Price,Qty,Load),Items))
	{
		?item_qty(ShopId, NItem, Qty2);
		if (Qty2 \== Qty)
		{
			-item_qty(ShopId, NItem, Qty2);
			+item_qty(ShopId, NItem, Qty);
		}
		if(not(item_price(NItem,Price2)) | (item_price(NItem,Price2) & Price > Price2))
		{
			-item_price(NItem,Price2);
			+item_price(NItem,Price);
		}		 
	}
	!!calculate_materials_prices;
	.	

+working(JobId,Items2,StorageId)
	: shopsList(List) & baseListJob(Items)
<-
	for ( .member(item(ItemId,Qty),Items) )
	{
		?find_shops(ItemId,List,Result);
		?best_shop(Result,Shop);
		if (buyList(ItemId,Qty2,Shop))
		{
			-buyList(ItemId,Qty2,Shop);
			+buyList(ItemId,Qty+Qty2,Shop);			
		} else {
			+buyList(ItemId,Qty,Shop);		
		}
	}
	.	
*/
	
	