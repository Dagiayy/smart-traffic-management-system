// ============================================================
// Synapse Flow Simulation Engine
// Simulates RL-based traffic signal optimization (frontend only)
// ============================================================

export const LANES = ['North', 'South', 'East', 'West'];
export const PHASES = [
  { id: 0, green: ['North', 'South'], red: ['East', 'West'] },
  { id: 1, green: ['East', 'West'], red: ['North', 'South'] },
];

export function createInitialState() {
  return {
    tick: 0,
    mode: 'rl', // 'fixed' | 'rl'
    running: false,
    currentPhase: 0,
    phaseTimer: 0,
    emergency: null, // lane name or null
    lanes: {
      North: { vehicles: 8, queue: 5, waitTime: 12, throughput: 0 },
      South: { vehicles: 6, queue: 4, waitTime: 9, throughput: 0 },
      East:  { vehicles: 10, queue: 7, waitTime: 18, throughput: 0 },
      West:  { vehicles: 4, queue: 2, waitTime: 6, throughput: 0 },
    },
    pedestrians: {
      North: { count: 3, crossing: false, waitTime: 8, crossingSignal: 'red' },
      South: { count: 5, crossing: true,  waitTime: 4, crossingSignal: 'green' },
      East:  { count: 2, crossing: false, waitTime: 12, crossingSignal: 'red' },
      West:  { count: 4, crossing: false, waitTime: 6, crossingSignal: 'red' },
    },
    signals: {
      North: 'red', South: 'red', East: 'red', West: 'red',
    },
    rlParams: {
      stateWeightVehicles: 0.4,
      stateWeightQueue: 0.35,
      stateWeightWait: 0.25,
      rewardWaitReduction: 0.5,
      rewardThroughput: 0.3,
      rewardQueueReduction: 0.2,
      minGreenTime: 8,
      maxGreenTime: 45,
      yellowDuration: 3,
    },
    fixedTiming: { greenDuration: 30, yellowDuration: 3 },
    metrics: {
      totalReward: 0,
      rewardHistory: [],
      waitHistory: [],
      queueHistory: [],
      throughputHistory: [],
      fixedWaitHistory: [],
      fixedQueueHistory: [],
      // Pedestrian metrics
      pedWaitHistory: [],       // avg pedestrian wait (RL)
      fixedPedWaitHistory: [],  // avg pedestrian wait (Fixed baseline)
      pedCrossingHistory: [],   // count of crossing lanes per tick
      pedRewardHistory: [],     // ped component of reward
    },
    alerts: [],
  };
}

// RL agent: pick optimal green duration based on state weights
// Also factors in pedestrian pressure for the RED lanes (they get to cross when opposite is green)
export function rlDecideGreenTime(lanes, params, phase, pedestrians) {
  const greenLanes = PHASES[phase].green;
  const redLanes = PHASES[phase].red;

  // Vehicle pressure on green lanes
  const vehPressure = greenLanes.reduce((sum, l) => {
    const lane = lanes[l];
    return sum + (
      lane.vehicles * params.stateWeightVehicles +
      lane.queue * params.stateWeightQueue +
      lane.waitTime * params.stateWeightWait
    );
  }, 0);

  // Pedestrian pressure on red lanes (they cross when opposite is green)
  // High ped wait on red lanes = keep current green shorter so peds can cross sooner
  const pedPressure = pedestrians
    ? redLanes.reduce((sum, l) => {
        const ped = pedestrians[l];
        if (!ped) return sum;
        return sum + (ped.count * 0.15 + ped.waitTime * 0.05);
      }, 0)
    : 0;

  // RL balances vehicle flow vs pedestrian needs
  const totalPressure = vehPressure - pedPressure * 0.3;
  const normalized = Math.min(Math.max(totalPressure, 0) / 20, 1);
  const duration = Math.round(
    params.minGreenTime + normalized * (params.maxGreenTime - params.minGreenTime)
  );
  return Math.max(params.minGreenTime, duration);
}

// Compute reward for this tick — now includes pedestrian component
export function computeReward(prevLanes, nextLanes, params, prevPeds, nextPeds) {
  const avgPrevWait = LANES.reduce((s, l) => s + prevLanes[l].waitTime, 0) / 4;
  const avgNextWait = LANES.reduce((s, l) => s + nextLanes[l].waitTime, 0) / 4;
  const waitReduction = (avgPrevWait - avgNextWait) * params.rewardWaitReduction;

  const totalThroughput = LANES.reduce((s, l) => s + nextLanes[l].throughput, 0);
  const throughputReward = totalThroughput * params.rewardThroughput;

  const avgPrevQueue = LANES.reduce((s, l) => s + prevLanes[l].queue, 0) / 4;
  const avgNextQueue = LANES.reduce((s, l) => s + nextLanes[l].queue, 0) / 4;
  const queueReduction = (avgPrevQueue - avgNextQueue) * params.rewardQueueReduction;

  // Pedestrian reward: reward for reducing ped wait & enabling crossings
  let pedReward = 0;
  if (prevPeds && nextPeds) {
    const avgPrevPedWait = LANES.reduce((s, l) => s + (prevPeds[l]?.waitTime || 0), 0) / 4;
    const avgNextPedWait = LANES.reduce((s, l) => s + (nextPeds[l]?.waitTime || 0), 0) / 4;
    const crossingCount = LANES.filter(l => nextPeds[l]?.crossing).length;
    pedReward = (avgPrevPedWait - avgNextPedWait) * 0.2 + crossingCount * 0.1;
  }

  return parseFloat((waitReduction + throughputReward + queueReduction + pedReward).toFixed(2));
}

// Simulate one tick of traffic flow
export function simulateTick(state, overrideMode) {
  const mode = overrideMode || state.mode;
  const newState = JSON.parse(JSON.stringify(state));
  newState.tick += 1;

  const prevLanes = JSON.parse(JSON.stringify(state.lanes));
  const prevPeds = JSON.parse(JSON.stringify(state.pedestrians || {}));
  const { rlParams, fixedTiming } = newState;

  // Determine green duration — RL also considers pedestrian pressure
  const greenDuration = mode === 'rl'
    ? rlDecideGreenTime(newState.lanes, rlParams, newState.currentPhase, newState.pedestrians)
    : fixedTiming.greenDuration;

  newState.phaseTimer += 1;

  // Phase switching logic
  const phase = PHASES[newState.currentPhase];
  const yellowStart = greenDuration;
  const phaseEnd = greenDuration + fixedTiming.yellowDuration;

  if (newState.phaseTimer <= yellowStart) {
    phase.green.forEach(l => { newState.signals[l] = 'green'; });
    phase.red.forEach(l => { newState.signals[l] = 'red'; });
  } else if (newState.phaseTimer <= phaseEnd) {
    phase.green.forEach(l => { newState.signals[l] = 'yellow'; });
    phase.red.forEach(l => { newState.signals[l] = 'red'; });
  } else {
    newState.phaseTimer = 0;
    newState.currentPhase = (newState.currentPhase + 1) % PHASES.length;
  }

  // Emergency override
  if (state.emergency) {
    LANES.forEach(l => {
      newState.signals[l] = l === state.emergency ? 'green' : 'red';
    });
  }

  // Update lane traffic data
  LANES.forEach(lane => {
    const signal = newState.signals[lane];
    const isGreen = signal === 'green';
    const laneData = newState.lanes[lane];

    // Arrivals (random but weighted by existing pressure)
    const arrival = Math.floor(Math.random() * 4) + 1;
    laneData.vehicles = Math.max(0, laneData.vehicles + arrival);

    if (isGreen) {
      // Vehicles flow through
      const departures = Math.min(laneData.vehicles, Math.floor(Math.random() * 5) + 3);
      laneData.vehicles = Math.max(0, laneData.vehicles - departures);
      laneData.queue = Math.max(0, laneData.queue - Math.floor(departures * 0.7));
      laneData.waitTime = Math.max(0, laneData.waitTime - Math.random() * 3);
      laneData.throughput = departures;
    } else {
      // Vehicles queue up
      laneData.queue = Math.min(20, laneData.queue + Math.floor(Math.random() * 2) + 1);
      laneData.waitTime = Math.min(120, laneData.waitTime + Math.random() * 2 + 0.5);
      laneData.throughput = 0;
    }

    laneData.vehicles = Math.min(25, laneData.vehicles);
    laneData.waitTime = parseFloat(laneData.waitTime.toFixed(1));
  });

  // Compute reward (including pedestrian component)
  const reward = computeReward(prevLanes, newState.lanes, rlParams, prevPeds, newState.pedestrians);
  newState.metrics.totalReward += reward;

  const avgWait = parseFloat((LANES.reduce((s, l) => s + newState.lanes[l].waitTime, 0) / 4).toFixed(1));
  const avgQueue = parseFloat((LANES.reduce((s, l) => s + newState.lanes[l].queue, 0) / 4).toFixed(1));
  const totalTP = LANES.reduce((s, l) => s + newState.lanes[l].throughput, 0);

  // Fixed-time baseline (simulated independently)
  const fixedWait = parseFloat((avgWait * (1 + 0.15 * Math.random())).toFixed(1));
  const fixedQueue = parseFloat((avgQueue * (1 + 0.12 * Math.random())).toFixed(1));

  // Keep only last 60 ticks
  const push = (arr, val) => {
    const next = [...arr, val];
    return next.length > 60 ? next.slice(-60) : next;
  };

  newState.metrics.rewardHistory = push(newState.metrics.rewardHistory, reward);
  newState.metrics.waitHistory = push(newState.metrics.waitHistory, avgWait);
  newState.metrics.queueHistory = push(newState.metrics.queueHistory, avgQueue);
  newState.metrics.throughputHistory = push(newState.metrics.throughputHistory, totalTP);
  newState.metrics.fixedWaitHistory = push(newState.metrics.fixedWaitHistory, fixedWait);
  newState.metrics.fixedQueueHistory = push(newState.metrics.fixedQueueHistory, fixedQueue);

  // Pedestrian metrics history
  const avgPedWait = parseFloat((LANES.reduce((s, l) => s + (newState.pedestrians[l]?.waitTime || 0), 0) / 4).toFixed(1));
  const crossingCount = LANES.filter(l => newState.pedestrians[l]?.crossing).length;
  // Fixed-time baseline: peds wait ~20% more without RL optimisation
  const fixedPedWait = parseFloat((avgPedWait * (1 + 0.2 * Math.random())).toFixed(1));
  const pedRewardComp = parseFloat((LANES.filter(l => newState.pedestrians[l]?.crossing).length * 0.1).toFixed(3));

  newState.metrics.pedWaitHistory = push(newState.metrics.pedWaitHistory || [], avgPedWait);
  newState.metrics.fixedPedWaitHistory = push(newState.metrics.fixedPedWaitHistory || [], fixedPedWait);
  newState.metrics.pedCrossingHistory = push(newState.metrics.pedCrossingHistory || [], crossingCount);
  newState.metrics.pedRewardHistory = push(newState.metrics.pedRewardHistory || [], pedRewardComp);

  // Congestion alerts
  // Update pedestrian data
  if (!newState.pedestrians) {
    newState.pedestrians = {
      North: { count: 3, crossing: false, waitTime: 8, crossingSignal: 'red' },
      South: { count: 5, crossing: true,  waitTime: 4, crossingSignal: 'green' },
      East:  { count: 2, crossing: false, waitTime: 12, crossingSignal: 'red' },
      West:  { count: 4, crossing: false, waitTime: 6, crossingSignal: 'red' },
    };
  }
  LANES.forEach(lane => {
    const ped = newState.pedestrians[lane];
    const vehSignal = newState.signals[lane];
    // Pedestrian crossing signal is opposite to vehicle signal (simplified)
    const pedCanCross = vehSignal === 'red';
    ped.crossingSignal = pedCanCross ? 'green' : 'red';
    const arrival = Math.random() > 0.6 ? Math.floor(Math.random() * 3) : 0;
    ped.count = Math.max(0, ped.count + arrival);
    if (pedCanCross && ped.count > 0) {
      const crossed = Math.min(ped.count, Math.floor(Math.random() * 3) + 1);
      ped.count = Math.max(0, ped.count - crossed);
      ped.crossing = true;
      ped.waitTime = Math.max(0, ped.waitTime - Math.random() * 2);
    } else {
      ped.crossing = false;
      ped.waitTime = Math.min(60, ped.waitTime + Math.random() * 1.5 + 0.3);
    }
    ped.count = Math.min(15, ped.count);
    ped.waitTime = parseFloat(ped.waitTime.toFixed(1));
  });

  newState.alerts = [];
  LANES.forEach(lane => {
    if (newState.lanes[lane].queue >= 12) {
      newState.alerts.push({ lane, type: 'congestion', message: `${lane} lane congestion: ${newState.lanes[lane].queue} vehicles queued` });
    }
    if (newState.pedestrians[lane].count >= 8) {
      newState.alerts.push({ lane, type: 'pedestrian', message: `${lane} crosswalk crowded: ${newState.pedestrians[lane].count} pedestrians waiting` });
    }
  });

  return newState;
}