import React, { createContext, useContext, useReducer, useEffect, useRef, useCallback } from 'react';
import { createInitialState, simulateTick } from './simulationEngine';

const SimulationContext = createContext(null);

function reducer(state, action) {
  switch (action.type) {
    case 'TICK':
      return simulateTick(state);
    case 'SET_MODE':
      return { ...state, mode: action.payload };
    case 'SET_RUNNING':
      return { ...state, running: action.payload };
    case 'RESET':
      return { ...createInitialState(), mode: state.mode };
    case 'SET_EMERGENCY':
      return { ...state, emergency: action.payload };
    case 'MANUAL_SIGNAL': {
      const newSignals = { ...state.signals };
      newSignals[action.payload.lane] = action.payload.color;
      return { ...state, signals: newSignals };
    }
    case 'SET_RL_PARAM': {
      return {
        ...state,
        rlParams: { ...state.rlParams, [action.payload.key]: action.payload.value }
      };
    }
    case 'SET_FIXED_TIMING': {
      return {
        ...state,
        fixedTiming: { ...state.fixedTiming, [action.payload.key]: action.payload.value }
      };
    }
    case 'FORCE_PHASE':
      return { ...state, currentPhase: action.payload, phaseTimer: 0 };
    default:
      return state;
  }
}

export function SimulationProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, createInitialState());
  const intervalRef = useRef(null);
  const appMode = useRef('admin'); // 'admin' | 'developer'
  const [mode, setMode] = React.useState('admin');

  const startSimulation = useCallback(() => {
    dispatch({ type: 'SET_RUNNING', payload: true });
  }, []);

  const pauseSimulation = useCallback(() => {
    dispatch({ type: 'SET_RUNNING', payload: false });
  }, []);

  const resetSimulation = useCallback(() => {
    dispatch({ type: 'SET_RUNNING', payload: false });
    dispatch({ type: 'RESET' });
  }, []);

  useEffect(() => {
    if (state.running) {
      intervalRef.current = setInterval(() => {
        dispatch({ type: 'TICK' });
      }, 1000);
    } else {
      clearInterval(intervalRef.current);
    }
    return () => clearInterval(intervalRef.current);
  }, [state.running]);

  const value = {
    state,
    dispatch,
    startSimulation,
    pauseSimulation,
    resetSimulation,
    appMode: mode,
    setAppMode: setMode,
  };

  return (
    <SimulationContext.Provider value={value}>
      {children}
    </SimulationContext.Provider>
  );
}

export function useSimulation() {
  const ctx = useContext(SimulationContext);
  if (!ctx) throw new Error('useSimulation must be used within SimulationProvider');
  return ctx;
}