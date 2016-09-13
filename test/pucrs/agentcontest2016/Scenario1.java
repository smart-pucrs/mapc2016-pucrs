package pucrs.agentcontest2016;

import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.competition2015.monitor.GraphMonitor;
import massim.server.Server;
import massim.test.InvalidConfigurationException;

public class Scenario1 {

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
					Server.main(new String[] { "--conf", "conf/test-complete-3sims/2016-r-random-conf.xml" });
				} catch (InvalidConfigurationException e) {
					e.printStackTrace();
				}
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
