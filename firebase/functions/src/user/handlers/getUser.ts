import { onCall } from "firebase-functions/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { UserProfile } from "../types";
import { requireAuthenticatedUser } from "../../shared/auth";
import { UserService } from "../shared/userService";

const userService = new UserService();

export const getUser = onCall(
  withCallHandler<void, UserProfile>(async (request) => {
    const uid = requireAuthenticatedUser(request).uid;
    return await userService.get(uid);
  }),
);
