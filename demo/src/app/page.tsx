import { Dashboard } from "../components/dashboard";
import { events } from "../lib/events";

export default function Home() {
  return <Dashboard events={events} />;
}
