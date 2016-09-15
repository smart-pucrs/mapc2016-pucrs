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

+simEnd
	: .my_name(Me)
<-
	!end_round;
	setMap;
	.wait(500);
	if (Me == vehicle15) {
		+max_bid_time(2000);
		+chargingPrice(0,0);
		+assembledInShops([]);
		+agentsFree(16);
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
	
+item(ItemId,Qty)
	: buyList(ItemId,Qty,ShopId)
<-
	-buyList(ItemId,Qty,ShopId);
	.

//+lastActionResult(Result)
//	: Result == failed_random & lastActionReal(Action) & step(Step)
//<-
//	.print("Failed to execute action ",Action," on step ",Step-1," due to the 1% random error.");
//	.
	
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
	-+workshopList([WorkshopId|List]);
	.

@dumpList[atomic]
+dump(DumpId,Lat,Lng,Price) 
	:  dumpList(List) & not .member(DumpId,List) 
<- 
	-+dumpList([DumpId|List]);
	.
	
+!notFree(Step2)
<-
	.drop_desire(free);
.
	
+!endCNP
: not winner(_,_,_,_)
<-
	!free;
.
+!endCNP.
	
@goHorse[atomic]	
+step(Step)
	: steps(TotalSteps) & Step >= TotalSteps - 100 & not goHorse
<-
	+goHorse;
	.print("|||GO-HORSE|||");
	.