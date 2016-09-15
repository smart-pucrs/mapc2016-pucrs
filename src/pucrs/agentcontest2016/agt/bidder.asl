+task(Task,CNPBoard,StorageIdS,TaskId)
	: .my_name(Me) & Me == vehicle15
<- 
	-task(Task,CNPBoard,StorageIdS,TaskId);
  	.

+task(Task,CNPBoard,StorageIdS,TaskId)
<- 
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
	.
	

+!create_bid(item(ItemId,Qty),StorageId,Bid,ShopId,TaskId)
	: product(ItemId, Volume, BaseList) & role(_, Speed, LoadCap, _, Tools) & load(Load) & shopList(List) 
<- 
	?find_shops(ItemId,List,ShopsViable);
	?closest_facility(ShopsViable, ShopId);
	?route(ShopId, RouteLenShop);
	?route(ShopId, StorageId, RouteLenStorage);	
	
	if ( (LoadCap - Load >= Volume * Qty + 15) ) {
		Bid = math.round((RouteLenShop / Speed) + (RouteLenStorage / Speed));		
	}
	else  {
		Bid = -1;
	}	
	.