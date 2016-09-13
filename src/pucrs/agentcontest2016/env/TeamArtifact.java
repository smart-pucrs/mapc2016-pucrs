package pucrs.agentcontest2016.env;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import cartago.*;


public class TeamArtifact extends Artifact {

	private static Logger logger = Logger.getLogger(TeamArtifact.class.getName());
	private static Map<String, Integer> shopItemsPrice = new HashMap<String, Integer>();
	private static List<String> shops = new ArrayList<String>();
	
	void init(){
		logger.info("Team Artifact has been created!");
	}
	
	public synchronized static void addShopItemsPrice(String shopId, String itemsPrice){
		//logger.info("$> Team Artifact (Shop - Items Price): " + shopId);
		if(shops.contains(shopId)){
			
		} else {
			shops.add(shopId);
			String itemsPriceAux = itemsPrice.replaceAll("availableItem\\(", "").replaceAll("\\)", "").replaceAll("\\[", "").replaceAll("\\]", "");
			String[] s = itemsPriceAux.split(",");
			int x = 0;
			String itemId = null;
			for (int i=0; i<s.length; i++) {
				if (x == 0)
					itemId = s[i];
				else if (x == 1) {
					if (shopItemsPrice.containsKey(itemId)) {
						if (shopItemsPrice.get(itemId) < Integer.parseInt(s[i]))
							shopItemsPrice.put(itemId, Integer.parseInt(s[i]));
					}
					else
						shopItemsPrice.put(itemId, Integer.parseInt(s[i]));
				}
				x++;
				if (x == 4)
					x = 0;
			}
//			logger.info("$> Team Artifact (Item - Price): " + shopItemsPrice);		
		}
	}
	
	@OPERATION void addPrices(){
		for (String key : shopItemsPrice.keySet()) {
			this.defineObsProperty("itemPrice",key,shopItemsPrice.get(key));
		}
		
	}	
	
	@OPERATION void addLoad(String agent, int load){
		this.defineObsProperty("load",agent,load);
	}

	@OPERATION void updateLoad(String agent, int load){
		this.removeObsPropertyByTemplate("load",agent,null);
		this.defineObsProperty("load",agent,load);
	}	
	
}