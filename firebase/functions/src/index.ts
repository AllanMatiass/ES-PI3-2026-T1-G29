// Autor: Allan Giovanni Matias Paes
import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ maxInstances: 10 });

export * from "./startups";
export * from "./auth";
export * from "./exchange";
export * from "./user";
export * from "./scripts/enableMfa";
