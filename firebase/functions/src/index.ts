// Autor: Allan Giovanni Matias Paes - 25008211
import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ maxInstances: 10 });

export * from "./auth";
export * from "./user";
export * from "./startups";
export * from "./exchange";
export * from "./events";
export * from "./scripts/enableMfa";
