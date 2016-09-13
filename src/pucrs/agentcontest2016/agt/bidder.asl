// PERIGO, AGENTES ESTÃO COMEÇANDO A DAR A BID ANTES DE TROCAREM DE PASSO
+task(Task,CNPBoard,StorageIdS,TaskId)
	: .my_name(Me) & Me == vehicle15
<- 
	-task(Task,CNPBoard,StorageIdS,TaskId);
  	.

+task(Task,CNPBoard,StorageIdS,TaskId)
<- 
//	.print("Starting my bid for task ",TaskId);
	lookupArtifact(CNPBoard,BoardId);
	focus(BoardId);
	.term2string(StorageId,StorageIdS);
  	!make_bid(Task,StorageId,BoardId,CNPBoard,TaskId);
  	.
	
+winner(List,JobId,StorageId,ShopId)
	: true
<- 
	.print("Awarded task to get ",List," at ",ShopId);
	for ( .member(item(ItemId,Qty),List) ) {
		+buyList(ItemId,Qty,ShopId);
	}
	!go_work(JobId,StorageId);
	.

+!make_bid(item(ItemId,Qty),StorageId,BoardId,CNPBoard,TaskId)
	: .my_name(Me)
<- 
	if (not .desire(go_dump) & not winner(_,_,_,_)) {
		!create_bid(item(ItemId,Qty),StorageId,Bid,ShopId,TaskId);
	}
	else {
		Bid = -1;
		ShopId = shop0;
	}
	bid(Bid,Me,ShopId,item(ItemId,Qty))[artifact_id(BoardId)];
//	.print("Bid submitted: ",Bid," for task: ",CNPBoard," at shop ",ShopId);
	.
	
// Se o agente j� est� trabalhando em um job no pr�ximo job envia uma proposta zerada
//+!create_bid(item(ItemId,Qty),StorageId,Bid,ShopId,TaskId)
//	: winner(_,_,_,_)
//<-
//	Bid = -1;
//	ShopId = shop0;
//	.
+!create_bid(item(ItemId,Qty),StorageId,Bid,ShopId,TaskId)
	: product(ItemId, Volume, BaseList) & role(_, Speed, LoadCap, _, Tools) & load(Load) & shopList(List) 
<- 
	?find_shops(ItemId,List,ShopsViable);
	?closest_facility(ShopsViable, ShopId);
	?route(ShopId, RouteLenShop);
	?route(ShopId, StorageId, RouteLenStorage);	
//	?calculate_bases_load(BaseList,Qty,0,LoadB);
	
	if ( (LoadCap - Load >= Volume * Qty + 15) ) {
		Bid = math.round((RouteLenShop / Speed) + (RouteLenStorage / Speed));		
	}
	else  {
		Bid = -1;
	}	
//	if ( (LoadB <= Volume * Qty) & (LoadCap - Load >= Volume * Qty)) {
//		Bid = math.round((RouteLenShop / Speed) + (RouteLenStorage / Speed));
//	}
//	if ( (LoadB <= Volume * Qty) & (LoadCap - Load < Volume * Qty) ) {
//		Bid = -1;
//	}
	.	 

/* 
@task[atomic]
+task(Task,CNPBoard) 
	: roled(Role, Speed, LoadCap, BatteryCap, Tools)
<- 
	.print("Found a task: ",Task);
	lookupArtifact(CNPBoard,BoardId);
	focus(BoardId);
	!make_bid(Task,BoardId,CNPBoard);
	. 
 
@winner[atomic]
+winner(BidId,Task,Items,JobId,StorageId) 
	: my_bid(BidId,Task)
<- 
	.print("Awarded!.");
	+noBids;
	!decomp([Items]);
	+working(JobId,[Items],StorageId);
	.
@winner2[atomic]	
+winner(BidId,Task,item(ItemId,Qty),JobId,StorageId) 
	: my_bid(X,Y) & not my_bid(BidId,Task) & product(ItemId, Volume, BaseList) & loadExpected(LoadE)
<- 
	.print("Not awarded.");
	-+loadExpected(LoadE - Volume * Qty);
	.
	
+!make_bid(Task,BoardId,CNPBoard)
	: not noBids
<- 
	!create_bid(Task,Bid);
	bid(Bid,BidId)[artifact_id(BoardId)];
	+my_bid(BidId,CNPBoard);
	.print("Bid submitted: ",Bid," - id: ",BidId, " for task: ",CNPBoard);
	.
-!make_bid(Task,BoardId,CNPBoard)
	: noBids
<- 
	.print("No more bids for me.");
	.
-!make_bid(Task,BoardId,CNPBoard)
<- 
	.print("Too late for submitting the bid.");
	.drop_all_intentions;
	.
	
@create_bid[atomic]	
+!create_bid(item(ItemId,Qty),Bid)
	: product(ItemId, Volume, BaseList) & loadExpected(LoadE) & load(Load) & loadTotal(LoadCap) & workshopList([WorkshopId|_]) & shopsList([shop(ShopId,_)|_]) & storageList([StorageId|_]) & roled(_, Speed, _, _, _)
<- 
	?closest_facility([WorkshopId], FacilityA, RouteLenWorkshop);
	?closest_facility([ShopId], FacilityB, RouteLenShop);
	?closest_facility([StorageId], FacilityC, RouteLenStorage);	
	?calculate_bases_load(BaseList,Qty,0,LoadB);
	
	?verify_tools([ItemId],[],ToolsMissing);
	if (ToolsMissing \== [])
	{
		.length(ToolsMissing,L);
		ToolFactor = 2 ** L;
	}
	else {
		ToolFactor = 1;
	}
	
	if ( (LoadB > Volume * Qty) & (LoadCap - Load >= LoadB + LoadE) )
	{
		-+loadExpected(LoadB + LoadE);
		Bid = math.round((RouteLenWorkshop / Speed) + (RouteLenShop / Speed) + (RouteLenStorage / Speed) * ToolFactor);		
	}
	if ( (LoadB > Volume * Qty) & (LoadCap - Load < LoadB + LoadE) ) 
	{
		Bid = 0;
	}	
	if ( (LoadB <= Volume * Qty) & (LoadCap - Load >= Volume * Qty + LoadE) )
	{
		-+loadExpected(Volume * Qty + LoadE);
		Bid = math.round((RouteLenWorkshop / Speed) + (RouteLenShop / Speed) + (RouteLenStorage / Speed) * ToolFactor);
	}
	if ( (LoadB <= Volume * Qty) & (LoadCap - Load < Volume * Qty + LoadE) )
	{
		Bid = 0;
	}
	.	 
*/