package pucrs.agentcontest2016;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.competition2015.monitor.GraphMonitor;
import massim.javaagents.App;
import massim.server.Server;
import massim.test.InvalidConfigurationException;

import org.junit.Before;
import org.junit.Test;

public class ScenarioAgainstScriptedDummies {

	@Before
	public void setUp() {

		new Thread(new Runnable() {
			@Override
			public void run() {
				GraphMonitor.main(new String[] { "-rmihost", "localhost", "-rmiport", "1099" });
			}
		}).start();

		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					Server.main(new String[] { "--conf", "conf/test-complete-3sims/2016-r-random-conf-complete.xml" });
				} catch (InvalidConfigurationException e) {
					e.printStackTrace();
				}
			}
		}).start();
		
		new Thread(new Runnable() {
			 @Override
			 public void run() {
				try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				App.main(new String[] {"conf/scripted-dummies/javaagentsconfig.xml"});
			 }
		}).start();

		try {
			JaCaMoLauncher runner = new JaCaMoLauncher();
			runner.init(new String[] { "test/pucrs/agentcontest2016/scenario1.jcm" });
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