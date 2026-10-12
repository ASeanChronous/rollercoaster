// Runs once when the server starts. Starting the engine here means statuses
// are computed and alerts evaluated from boot, not from the first visitor.
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { getEngine } = await import("./lib/engine");
    getEngine();
  }
}
