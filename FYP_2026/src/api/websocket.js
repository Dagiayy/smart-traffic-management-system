/**
 * api/websocket.js
 * Manages WebSocket connections to the Django Channels backend.
 *
 * Channels available:
 *   ws/violations/feed/          — live violation events (admin panel)
 *   ws/alerts/                   — system alerts (admin + dev)
 *   ws/ai/session/{id}/          — RL training metrics (dev panel)
 *   ws/traffic/{intersection_id}/ — live signal states (admin live traffic)
 */

const WS_BASE = (() => {
  const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
  return `${protocol}://${window.location.host}`;
})();

class ManagedWebSocket {
  constructor(path, handlers = {}) {
    this.path = path;
    this.handlers = handlers;
    this.ws = null;
    this._reconnectTimer = null;
    this._intentionallyClosed = false;
    this._connect();
  }

  _connect() {
    this.ws = new WebSocket(`${WS_BASE}${this.path}`);

    this.ws.onopen = () => {
      this.handlers.onOpen?.();
    };

    this.ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        this.handlers.onMessage?.(msg);
      } catch {
        // ignore malformed frames
      }
    };

    this.ws.onerror = (err) => {
      this.handlers.onError?.(err);
    };

    this.ws.onclose = () => {
      this.handlers.onClose?.();
      if (!this._intentionallyClosed) {
        this._reconnectTimer = setTimeout(() => this._connect(), 3000);
      }
    };
  }

  send(data) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
    }
  }

  close() {
    this._intentionallyClosed = true;
    clearTimeout(this._reconnectTimer);
    this.ws?.close();
  }
}

// ── Factory helpers ───────────────────────────────────────────────────────

/** Subscribe to real-time violation events */
export function openViolationFeed(onMessage) {
  return new ManagedWebSocket('/ws/violations/feed/', { onMessage });
}

/** Subscribe to system-wide alerts */
export function openAlertsChannel(onMessage) {
  return new ManagedWebSocket('/ws/alerts/', { onMessage });
}

/** Subscribe to RL training updates for a specific session */
export function openAISessionChannel(sessionId, onMessage) {
  return new ManagedWebSocket(`/ws/ai/session/${sessionId}/`, { onMessage });
}

/** Subscribe to live signal state for an intersection */
export function openTrafficChannel(intersectionId, onMessage) {
  return new ManagedWebSocket(`/ws/traffic/${intersectionId}/`, { onMessage });
}
