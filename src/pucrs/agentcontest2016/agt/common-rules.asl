find_shops(ItemId,[],[]).
find_shops(ItemId,[shop(ShopId,ListItems)|List],[ShopId|Result]) :- .member(item(ItemId,_,_,_),ListItems) & find_shops(ItemId,List,Result).
find_shops(ItemId,[shop(ShopId,ListItems)|List],Result) :- not .member(item(ItemId,_,_,_),ListItems) & find_shops(ItemId,List,Result).

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

find_shops_id([],Temp,Result) :- Result = Temp.
find_shops_id([shop(ShopId,_)|List],Temp,Result) :- find_shops_id(List,[ShopId|Temp],Result).

getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- shop(FacilityId, LatAux, LonAux,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- storage(FacilityId, LatAux, LonAux,_,_,_,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- dump(FacilityId,LatAux,LonAux,_) & Flat=LatAux & Flon=LonAux.