package pucrs.agentcontest2016.env;

import jason.JasonException;
import jason.NoValueException;
import jason.asSyntax.Literal;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.logging.Logger;

import massim.competition2015.scenario.Location;
import cartago.AgentId;
import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import cartago.ObsProperty;
import eis.EILoader;
import eis.EnvironmentInterfaceStandard;
import eis.exceptions.ActException;
import eis.exceptions.NoEnvironmentException;
import eis.exceptions.PerceiveException;
import eis.iilang.Action;
import eis.iilang.EnvironmentState;
import eis.iilang.Parameter;
import eis.iilang.Percept;

public class EISArtifact extends Artifact {

	private Logger logger = Logger.getLogger(EISArtifact.class.getName());

	private Map<String, AgentId> agentIds;
	private Map<String, String> agentToEntity;
	
	private static Set<String> agents = new ConcurrentSkipListSet<String>();

	private EnvironmentInterfaceStandard ei;
	private boolean receiving;
//	private boolean test = true;
	private int lastStep = -1;
	private int round = 0;
	private String maps[] = new String[] { "london", "hannover", "sanfrancisco" };
//	private String maps[] = new String[] { "hannover", "sanfrancisco","london", };
//	private String maps[] = new String[] { "sanfrancisco", "hannover", "london" };
	
	
	public EISArtifact() {
		agentIds      = new ConcurrentHashMap<String, AgentId>();
		agentToEntity = new ConcurrentHashMap<String, String>();
		MapHelper.init(maps[round], 0.001, 0.0002);
	}

	protected void init() throws IOException, InterruptedException {
		try {
			ei = EILoader.fromClassName("massim.eismassim.EnvironmentInterface");
			if (ei.isInitSupported())
				ei.init(new HashMap<String, Parameter>());
			if (ei.getState() != EnvironmentState.PAUSED)
				ei.pause();
			if (ei.isStartSupported())
				ei.start();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		receiving = true;
		execInternalOp("receiving");
	}
	
	public static Set<String> getRegisteredAgents(){
		return agents;
	}
	
	@OPERATION
	void register(String entity)  {
		try {
			String agent = getOpUserId().getAgentName();
			agents.add(agent);
			ei.registerAgent(agent);
			ei.associateEntity(agent, entity);
			agentToEntity.put(agent, entity);
			agentIds.put(agent, getOpUserId());
			logger = Logger.getLogger(EISArtifact.class.getName()+"_"+agent);
			logger.info("Registering " + agent + " to entity " + entity);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}	
/*
	@OPERATION
	void register() {
		try {
			String agent = getOpUserId().getAgentName();
			ei.registerAgent(agent);
			ei.associateEntity(agent, agent);
			System.out.println("Registering: " + agent);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@OPERATION
	void register_freeconn() {
		try {
			String agent = getOpUserId().getAgentName();
			ei.registerAgent(agent);
			String entity = ei.getFreeEntities().iterator().next();
			ei.associateEntity(agent, entity);
			agentIds.put(agent, getOpUserId());
			System.out.println("Registering " + agent + " to entity " + entity);
			signal(agentIds.get(agent), "serverName", Literal.parseLiteral(entity.substring(10).toLowerCase()));
		} catch (AgentException e) {
			e.printStackTrace();
		} catch (RelationException e) {
			e.printStackTrace();
		}
	}
*/
	@OPERATION
	void action(String action) throws NoValueException {
		try {
			String agent = getOpUserName();
			Action a = Translator.literalToAction(action);
			ei.performAction(agent, a, agentToEntity.get(agent));
		} catch (ActException e) {
			e.printStackTrace();
		}
	}
	
	@INTERNAL_OPERATION
	void setMap(){
		round++;
		MapHelper.init(maps[round], 0.001, 0.0002);
		System.out.println("$> MAP: " + maps[round]);
	}
	
	@INTERNAL_OPERATION
	void receiving() throws JasonException {
		lastStep = -1;
		Collection<Percept> previousPercepts = new ArrayList<Percept>();
		
		while (receiving) {
			await_time(100);
			for (String agent: agentIds.keySet()) {
				try {
					Collection<Percept> percepts = ei.getAllPercepts(agent).get(agentToEntity.get(agent));
					populateTeamArtifact(percepts);
					//logger.info("***"+percepts);
					if (percepts.isEmpty())
						break;
					int currentStep = getCurrentStep(percepts);
					if (lastStep != currentStep) { // only updates if it is a new step
						lastStep = currentStep;
						filterLocations(agent, percepts);
						//logger.info("Agent "+agent);
						updatePerception(agent, previousPercepts, percepts);
						previousPercepts = percepts;
					}
				} catch (PerceiveException | NoEnvironmentException e) {
					e.printStackTrace();
				}
			}
		}
	}

	private int getCurrentStep(Collection<Percept> percepts) {
		for (Percept percept : percepts) {
			if (percept.getName().equals("step")) {
				//logger.info(percept+" "+percept.getParameters().getFirst());
				return new Integer(percept.getParameters().getFirst().toString());
			}
		}
		return -10;
	}
	
	private void populateTeamArtifact(Collection<Percept> percepts){
		for (Percept percept : percepts) {
			String name = percept.getName();
			/*Verifying available items in a nearby shop*/
			if(name.equals("shop")){
				for(Parameter p: percept.getParameters())
					if(p.toString().contains("availableItem"))
						TeamArtifact.addShopItemsPrice(percept.getParameters().get(0).toString(), percept.getParameters().get(3).toString());
			}
		}
	}

	private void updatePerception(String agent, Collection<Percept> previousPercepts, Collection<Percept> percepts) throws JasonException {
		if (agent.equals("vehicle15")) {
			// compute removed perception
			for (Percept old: previousPercepts) {
				if (step_obs_propv1.contains(old.getName())) {
					if (!percepts.contains(old)) { // not perceived anymore
						Literal literal = Translator.perceptToLiteral(old);
						removeObsPropertyByTemplate(old.getName(), (Object[]) literal.getTermsArray());
//						logger.info("removing old perception "+literal);
					}
				}
			}
		}
		else {
			for (Percept old: previousPercepts) {
				if (step_obs_prop.contains(old.getName())) {
					if (!percepts.contains(old)) { // not perceived anymore
						Literal literal = Translator.perceptToLiteral(old);
						removeObsPropertyByTemplate(old.getName(), (Object[]) literal.getTermsArray());
						//logger.info("removing old perception "+literal);
					}
				}
			}
		}
		
		// compute new perception
		Literal step = null;
		if (agent.equals("vehicle15")) {
//			logger.info("############################### START");
			for (Percept percept: percepts) {
				if (step_obs_propv1.contains(percept.getName())) {
					if (!previousPercepts.contains(percept) || percept.getName().equals("lastAction")) { // really new perception 
						Literal literal = Translator.perceptToLiteral(percept);
						if (percept.getName().equals("step")) {
							step = literal;
						} else if (percept.getName().equals("simEnd")) {
//							cleanObsProps(step_obs_propv1);
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
							cleanObsProps(match_obs_prop);
							lastStep = -1;
							break;
						} else {
//							logger.info("adding "+literal);
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
						}
					}
				} if (match_obs_prop.contains(percept.getName())) {
					Literal literal = Translator.perceptToLiteral(percept);
//					logger.info("adding "+literal);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());				
				}
			}
//			logger.info("############################### END");
		}
		else {
//			logger.info("############################### START");
			for (Percept percept: percepts) {
				if (step_obs_prop.contains(percept.getName())) {
					if (!previousPercepts.contains(percept) || percept.getName().equals("lastAction")) { // really new perception 
						Literal literal = Translator.perceptToLiteral(percept);
						if (percept.getName().equals("step")) {
							step = literal;
						} else if (percept.getName().equals("simEnd")) {
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
							cleanObsProps(match_obs_prop);
							lastStep = -1;						
							break;
						} else {
//							logger.info("adding "+literal);
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
						}
					}
				} if (match_obs_prop.contains(percept.getName())) {
					Literal literal = Translator.perceptToLiteral(percept);
					//logger.info("adding "+literal);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());				
				}
			}
//			logger.info("############################### END");
		}
			
		/*
		cleanObsProps(step_obs_prop);
		Literal step = null;
		for (Percept percept : percepts) {
			if (step_obs_prop.contains(percept.getName()) || match_obs_prop.contains(percept.getName())) {
				Literal literal = Translator.perceptToLiteral(percept);
				if (literal.getFunctor().equals("step")) {
					step = literal;
				} else if (literal.getFunctor().equals("simEnd")) {
					cleanObsProps(step_obs_prop);
					cleanObsProps(match_obs_prop);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());
					break;
				} else {
					logger.info("adding "+literal);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());
				}
			}
		}
		*/
		
		if (step != null) {
			//logger.info("adding "+step);
			//signal(agentIds.get(agent), step.getFunctor(), (Object[]) step.getTermsArray());
//			logger.info("adding "+step);
			defineObsProperty(step.getFunctor(), (Object[]) step.getTermsArray());
		}

	}
	
	private void cleanObsProps(Set<String> obSet) {
		for (String obs: obSet) {
			cleanObsProp(obs);
		}
	}

	private void cleanObsProp(String obs) {
		ObsProperty ob = getObsProperty(obs);
		while (ob != null) {
//			logger.info("Removing "+ob);
			removeObsProperty(obs);
			ob = getObsProperty(obs);
		}
	}

	@OPERATION
	void stopReceiving() {
		receiving = false;
	}
	
//	static Set<String> as_signal = new HashSet<String>( Arrays.asList(new String[] {
//	"entity",
//	"fPosition",
//	"lastActionParam",
//	"lat",
//	"lon",
//	"requestAction",
//	"route",
//	"routeLength",
//	"team",
//	"timestamp",		
//}));

	static Set<String> match_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"simStart",
		"map",
		"steps",
		"product",
		"role",
	}));
	
	static Set<String> step_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"simStart",
		"map",
		"chargingStation",
//		"visibleChargingStation",
		"shop",			
		"storage",
//		"workshop",
		"dump",
		"lat",
		"lon",
		"charge",
		"load",
		"inFacility",
		"item",
//		"jobTaken",
		"step",
		"simEnd",		
//		"pricedJob",
//		"auctionJob",
		"lastAction",
		"lastActionResult",
	}));
	
	static Set<String> step_obs_propv1 = new HashSet<String>( Arrays.asList(new String[] {
			"simStart",
			"map",
			"chargingStation",
//			"visibleChargingStation",
			"shop",			
			"storage",
//			"workshop",
			"dump",
			"lat",
			"lon",
			"charge",
			"load",
			"inFacility",
			"item",
//			"jobTaken",
			"step",
			"simEnd",		
			"pricedJob",
//			"auctionJob",
			"lastAction",
			"lastActionResult",
		}));	
	
	static List<String> location_perceptions = Arrays.asList(new String[] { "shop", "storage", "workshop", "chargingStation", "dump", "entity" });

	private void filterLocations(String agent, Collection<Percept> perceptions) {
		double agLat = Double.NaN, agLon = Double.NaN;
		for (Percept perception : perceptions) {
			if(perception.getName().equals("lon")){
				agLon = Double.parseDouble(perception.getParameters().get(0).toString());
			}
			if(perception.getName().equals("lat")){
				agLat = Double.parseDouble(perception.getParameters().get(0).toString());
			}
			if (location_perceptions.contains(perception.getName())) {
				boolean isEntity = perception.getName().equals("entity"); // Second parameter of entity is the team. :(
				LinkedList<Parameter> parameters = perception.getParameters();
				String facility = parameters.get(0).toString();
				if (!MapHelper.hasLocation(facility)) {
					String local = parameters.get(0).toString();
					double lat = Double.parseDouble(parameters.get(isEntity ? 2 : 1).toString());
					double lon = Double.parseDouble(parameters.get(isEntity ? 3 : 2).toString());
					MapHelper.addLocation(local, new Location(lon, lat));
				}
			}
		}
		if(!Double.isNaN(agLat) && !Double.isNaN(agLon)){
			MapHelper.addLocation(agent, new Location(agLon, agLat));
		}
	}	
	
/*
	static List<String> agentise = Arrays.asList(new String[]{
		"charge",
		"fPosition",
		"inFacility",
		"item",
		"lastAction",
		"lastActionParam",
		"lastActionResult",
		"lat",
		"load",
		"lon",
		"requestAction",
		"role",
		"route",
		"routeLength",
	});

	public static List<Percept> agentise( String agent, Collection<Percept> perceptions ){
		// TODO change entity name (a1) to Jason agent name (vehicle1)
		List<Percept> list = new ArrayList<Percept>();
		for(Percept perception : perceptions){
			if(agentise.contains(perception.getName())){
				LinkedList<Parameter> parameters = perception.getClonedParameters();
				parameters.addFirst(new Identifier(agent));
				perception = (Percept) perception.clone();
				perception.setParameters(parameters);
			}
			list.add(perception);
		}
		return list;
	}

	
	@INTERNAL_OPERATION
	void receiving() throws JasonException {
		// Set<Percept> leader_percepts = new HashSet<Percept>();
		boolean filterIsFiltered = false;
		int lastStep = -1;
		Collection<Percept> previousPercepts = new ArrayList<Percept>();
		while (receiving) {
			// leader_percepts.clear();
			if(test)
				{
					await_time(500);
					signal("serverName", Literal.parseLiteral(entity.substring(10).toLowerCase()));
					test = false;
				}
			try {
				Literal step = null;
				Collection<Percept> percepts = ei.getAllPercepts(this.agent).get(this.entity);
				// leader_percepts.addAll(agentise(agent, percepts));
				filterLocations(agent, percepts);
				
				// TODO change map when round finish
				
				for (Percept percept : filter(percepts)) {
					String name = percept.getName();
					/*Verifying available items in a nearby shop
					if(name.equals("shop")){
						for(Parameter p: percept.getParameters())
							if(p.toString().contains("availableItem"))
								pinShopAvailableItems(percept, p);
					}
					Literal literal = Translator.perceptToLiteral(percept);
					if (literal.getFunctor().equals("step"))
						step = literal;
					else
						signal(name, (Object[]) literal.getTermsArray());
				}
				if (step != null)
					signal(step.getFunctor(), (Object[]) step.getTermsArray());
			} catch (PerceiveException | NoEnvironmentException | JasonException e) {
//				e.printStackTrace();
			}
			// Filtering the filter 
			if(!filterIsFiltered){
				for(String f:another_agent_filter.keySet())
					another_agent_filter.put(f, true);
				filterIsFiltered = true;
			}
			
//			signal("ok");

			for (Percept percept : leader_percepts) {
				String name = percept.getName();
				Literal literal = Translator.perceptToLiteral(percept);
				signal(leader, name, (Object[]) literal.getTermsArray());
			}
*/
/* 			exemplo de propriedade observavel
			private String propertyName = "set_a_name"; //nome da propriedade
			defineObsProperty(propertyName, 0); //define a new observable property and sets initial value
			...
			ObsProperty prop = getObsProperty(propertyName); //get current value of observable property
			prop.updateValues(0); //updates current value of property (I am almost sure that this command generates a signal automatically)
			signal(propertyName);

			await_time(100);
		}
	}
	
	static Map<String, Boolean> another_agent_filter = new HashMap<String, Boolean>();
	static{
		another_agent_filter.put("dump", false);
		another_agent_filter.put("storage", false);
		another_agent_filter.put("workshop", false);
		another_agent_filter.put("chargingStation", false);
	}
	
	static List<String> agent_filter = Arrays.asList(new String[]{
		"charge",
//		"entity",
//		"fPosition",
		"inFacility",
		"item",
		"lastAction",
//		"lastActionParam",
//		"lastActionResult",
//		"lat",
		"load",
//		"lon",
//		"requestAction",
		"role",
		"step",
//		"route",
//		"routeLength",
//		"team",
//		"timestamp",		

		"steps",
		"jobTaken",
		"simEnd",		
		"auctionJob",		
		"pricedJob",
		"product",		
		"shop",
		"storage",
		"workshop",
		"chargingStation",
		"dump",
	});
	
	public static List<Percept> filter( Collection<Percept> perceptions ){
		List<Percept> list = new ArrayList<Percept>();
		for(Percept perception : perceptions){
			if(agent_filter.contains(perception.getName())){
				// Filtering the filter
				if(another_agent_filter.containsKey(perception.getName()) && !another_agent_filter.get(perception.getName()))
					continue;
				
				list.add(perception);
			}
		}
		return list;
	}
		

	
	//This method defines/updates an observed property for consulting available items (price and amount) in the shops. 
	// @param Percept percept
	// @param Parameter param
	public void pinShopAvailableItems(Percept percept, Parameter param) {
		String propertyName = "availableItems";
		ObsProperty property = getObsProperty(propertyName);
		if (property == null) {
			defineObsProperty(propertyName, percept.getParameters().get(0), new ParameterList());
			property = getObsProperty(propertyName);
		}

		property.updateValues(percept.getParameters().get(0), param);
		signal(propertyName);
	}
*/
}