best_shop([Shop|_],Shop).

find_shops(ItemId,[],[]).
find_shops(ItemId,[shop(ShopId,ListItems)|List],[ShopId|Result]) :- .member(item(ItemId,_,_,_),ListItems) & find_shops(ItemId,List,Result).
find_shops(ItemId,[shop(ShopId,ListItems)|List],Result) :- not .member(item(ItemId,_,_,_),ListItems) & find_shops(ItemId,List,Result).

verify_item(ItemId,Qty,Result) :- item(ItemId,Qty) & Result = true.
verify_item(ItemId,Qty,Result) :- Result = false.

closest_facility(List, Facility) :- role(Role, _, _, _, _) & pucrs.agentcontest2016.actions.closest(Role, List, Facility).
closest_facility(List, Facility1, Facility2) :- role(Role, _, _, _, _) & pucrs.agentcontest2016.actions.closest(Role, List, Facility1, Facility2).
closest_facility_from_center(CenterLat, CenterLon, List, ShopId) :- Role = "Drone" & pucrs.agentcontest2016.actions.closest(Role, CenterLat, CenterLon, List, ShopId).

route(FacilityId, RouteLen) :- role(Role, _, _, _, _) & pucrs.agentcontest2016.actions.route(Role, FacilityId, RouteLen).
route(FacilityId1, FacilityId2, RouteLen) :- role(Role, _, _, _, _) & pucrs.agentcontest2016.actions.route(Role, FacilityId1, FacilityId2, RouteLen).
route_drone_from_center(CenterLat, CenterLon, FacilityId, RouteLen) :- Role = "Drone" & pucrs.agentcontest2016.actions.route(Role, CenterLat, CenterLon, FacilityId, RouteLen).
route_car_from_center(CenterLat, CenterLon, FacilityId, RouteLen) :- Role = "Car" & pucrs.agentcontest2016.actions.route(Role, CenterLat, CenterLon, FacilityId, RouteLen).

enough_battery(FacilityId1, FacilityId2, Result) :- role(Role, Speed, _, _, _) & pucrs.agentcontest2016.actions.route(Role, FacilityId1, RouteLen1) & pucrs.agentcontest2016.actions.route(Role, FacilityId1, FacilityId2, RouteLen2) & charge(Battery) & ((Battery > ((RouteLen1 / Speed * 10) + (RouteLen2 / Speed * 10) + 10) & Result = true) | (Result = false)).
enough_battery2(FacilityAux, FacilityId1, FacilityId2, Result, Battery) :- role(Role, Speed, _, _, _) & pucrs.agentcontest2016.actions.route(Role, FacilityAux, FacilityId1, RouteLen1) & pucrs.agentcontest2016.actions.route(Role, FacilityId1, FacilityId2, RouteLen2) & ((Battery > ((RouteLen1 / Speed * 10) + (RouteLen2 / Speed * 10) + 10) & Result = true) | (Result = false)).
enough_battery_charging(FacilityId, Result) :- role(Role, Speed, _, _, _) & pucrs.agentcontest2016.actions.route(Role, FacilityId, RouteLen)& charge(Battery) & ((Battery > ((RouteLen / Speed * 10) + 10) & Result = true) | (Result = false)).
enough_battery_charging2(FacilityAux, FacilityId, Result, Battery) :- role(Role, Speed, _, _, _) & pucrs.agentcontest2016.actions.route(Role, FacilityAux, FacilityId, RouteLen) & ((Battery > ((RouteLen / Speed * 10) + 10) & Result = true) | (Result = false)).

select_bid([],bid(AuxBid,AuxBidAgent,AuxShopId,AuxItem),bid(BidWinner,BidAgentWinner,ShopIdWinner,ItemWinner)) :- BidWinner = AuxBid & BidAgentWinner = AuxBidAgent & ShopIdWinner = AuxShopId  & ItemWinner = AuxItem.
select_bid([bid(Bid,BidAgent,ShopId,item(ItemId,Qty))|Bids],bid(AuxBid,AuxBidAgent,AuxShopId,AuxItem),BidWinner) :- Bid \== -1 & Bid < AuxBid & ( ((not awarded(BidAgent,_,_)) )  | (awarded(BidAgent,ShopId,_) & product(ItemId,Volume,BaseList) & .term2string(BidAgent,BidAgentS) & load(BidAgentS,Load) & Load >= Volume*Qty ) ) & select_bid(Bids,bid(Bid,BidAgent,ShopId,item(ItemId,Qty)),BidWinner).
select_bid([bid(Bid,BidAgent,ShopId,Item)|Bids],bid(AuxBid,AuxBidAgent,AuxShopId,AuxItem),BidWinner) :- select_bid(Bids,bid(AuxBid,AuxBidAgent,AuxShopId,AuxItem),BidWinner).

compare_jobs(JobId, StorageId, Begin, End, Reward, Items) :- JobActive = End-Begin & .sort(Items,ItemsS) & .concat(StorageId,JobActive,Reward,ItemsS,String1) & post_job_priced(Reward2, JobActive2, StorageId2, Items2) & .sort(Items2,Items2S) & .concat(StorageId2, JobActive2, Reward2, Items2S,String2) & String1 == String2.
compare_jobs(JobId, StorageId, Begin, End, Fine, MaxBid, Items) :- JobActive = End-Begin & .sort(Items,ItemsS) & .concat(StorageId,JobActive,Fine,MaxBid,ItemsS,String1) & post_job_auction(MaxBid2, Fine2, JobActive2, AuctionActive, StorageId2, Items2) & .sort(Items2,Items2S) & .concat(StorageId2,JobActive2,Fine2,MaxBid2,Items2S,String2) & String1 == String2.

calculate_bases_load([],Qty,Aux,LoadB) :- LoadB = Qty * Aux.
calculate_bases_load([consumed(ItemId,Qty2)|BaseList],Qty,Aux,LoadB) :- product(ItemId,Volume,BaseList2) & BaseList2 == [] & calculate_bases_load(BaseList,Qty,Volume * Qty2 + Aux,LoadB).
calculate_bases_load([consumed(ItemId,Qty2)|BaseList],Qty,Aux,LoadB) :- product(ItemId,Volume,BaseList2) & BaseList2 \== [] & calculate_bases_load(BaseList2,Qty,Aux,LoadB2) & calculate_bases_load(BaseList,Qty,LoadB2,LoadB).
calculate_bases_load([tools(ToolId,Qty2)|BaseList],Qty,Aux,LoadB) :- calculate_bases_load(BaseList,Qty,Aux,LoadB).

find_shops_id([],Temp,Result) :- Result = Temp.
find_shops_id([shop(ShopId,_)|List],Temp,Result) :- find_shops_id(List,[ShopId|Temp],Result).

getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- shop(FacilityId, LatAux, LonAux,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- storage(FacilityId, LatAux, LonAux,_,_,_,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- dump(FacilityId,LatAux,LonAux,_) & Flat=LatAux & Flon=LonAux.

/* 
//low_battery :- charge(Battery) & chargeTotal(BatteryCap) & Battery < BatteryCap*60/100.
low_battery :- not goHorse & charge(Battery) & roled(_, Speed, _, _, _) & chargingList(List) & closest_facility(List, Facility, RouteLen)
              & (RouteLen / Speed * 10 > Battery - 20) .
              // Battery to the closest station > Battery w/ margin => Time to recharge
              // It waste 10 of battery per motion
              // TODO keep watching if 10 will remain the same for all roles


closest_facility_drone(List, Facility, RouteLen) :- Role = "drone" & pucrs.agentcontest2016.actions.closest(Role, List, Facility, RouteLen).

verify_items([item(ItemId,Qty)|List]) :- item(ItemId,Qty2) & Qty2 >= Qty & verify_items(List).
verify_items([consumed(ItemId,Qty)|List]) :- item(ItemId,Qty2) & Qty2 >= Qty & verify_items(List).
verify_items([tools(ItemId,Qty)|List]) :- item(ItemId,Qty) & verify_items(List).

verify_tools([],Aux,Result) :- Result = Aux.
verify_tools([ItemId|List],Aux,Result) :- product(ItemId, Volume, BaseList) & get_missing_tools(BaseList,[],ListTools,ItemId) & .concat(ListTools,Aux,ResultAux) & verify_tools(List,ResultAux,Result).

get_missing_tools([],Aux,ListTools,ItemId) :- ListTools = Aux.
get_missing_tools([tools(ToolId,Qty)|List],Aux,ListTools,ItemId) :- item(ToolId,0) & .concat([assemble(ItemId,ToolId)],Aux,ResultAux) & get_missing_tools(List,ResultAux,ListTools,ItemId).
get_missing_tools([tools(ToolId,Qty)|List],Aux,ListTools,ItemId) :- item(ToolId,1) & get_missing_tools(List,Aux,ListTools,ItemId).
get_missing_tools([consumed(ItemId2,Qty)|List],Aux,ListTools,ItemId) :- get_missing_tools(List,Aux,ListTools,ItemId).

count(ItemId,[],Aux,Qty) :- Qty = Aux.
count(ItemId,[ItemId|ListAssemble],Aux,Qty) :- Aux2 = Aux+1 & count(ItemId,ListAssemble,Aux2,Qty).
count(ItemId,[ItemId2|ListAssemble],Aux,Qty) :- count(ItemId,ListAssemble,Aux,Qty).

select_bid([],bid(AuxBid,AuxBidId),bid(BidWinner,BidIdWinner)) :- BidWinner = AuxBid & BidIdWinner = AuxBidId.
select_bid([bid(Bid,BidId)|Bids],bid(AuxBid,AuxBidId),BidWinner) :- Bid \== 0 & Bid < AuxBid & select_bid(Bids,bid(Bid,BidId),BidWinner).
select_bid([bid(Bid,BidId)|Bids],bid(AuxBid,AuxBidId),BidWinner) :- select_bid(Bids,bid(AuxBid,AuxBidId),BidWinner).

calculate_bases_load([],Qty,Aux,LoadB) :- LoadB = Qty * Aux.
calculate_bases_load([consumed(ItemId,Qty2)|BaseList],Qty,Aux,LoadB) :- product(ItemId,Volume,BaseList2) & BaseList2 == [] & calculate_bases_load(BaseList,Qty,Volume * Qty2 + Aux,LoadB).
calculate_bases_load([consumed(ItemId,Qty2)|BaseList],Qty,Aux,LoadB) :- product(ItemId,Volume,BaseList2) & BaseList2 \== [] & calculate_bases_load(BaseList2,Qty,Aux,LoadB2) & calculate_bases_load(BaseList,Qty,LoadB2,LoadB).
calculate_bases_load([tools(ToolId,Qty2)|BaseList],Qty,Aux,LoadB) :- calculate_bases_load(BaseList,Qty,Aux,LoadB).

is_tool(ItemId) :- ItemId == tool1 | ItemId == tool2 | ItemId == tool3 | ItemId == tool4.

items_has_price([item(NItem,Price,Qty,Load)]):- Price\==0.
items_has_price([item(NItem,Price,Qty,Load)|L]):- Price\==0.
*/