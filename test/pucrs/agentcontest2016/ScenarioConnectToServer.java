package pucrs.agentcontest2016;

import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;

public class ScenarioConnectToServer {

	@Before
	public void setUp() {
		
		try {
			JaCaMoLauncher runner = new JaCaMoLauncher();
			runner.init(new String[] { "test/pucrs/agentcontest2016/scenario.jcm" });
			runner.getProject().addSourcePath("./src/pucrs/agentcontest2016/agt");
			runner.create();
			runner.start();
			runner.waitEnd();
			runner.finish();
		} catch (JasonException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void run() {
	}

}
