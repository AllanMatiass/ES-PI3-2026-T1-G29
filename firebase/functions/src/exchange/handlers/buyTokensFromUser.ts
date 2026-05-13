// firebase/functions/src/exchange/handlers/buyTokensFromUser.ts

import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { BuyFromUserService } from "../shared/buyFromUserService";
import {
  BuyTokensFromUserRequestDTO,
  BuyTokensFromUserResponseDTO,
} from "../types/dtos";

const buyFromUserService = new BuyFromUserService();

export const buyTokensFromUser = onCall(
  withCallHandler<BuyTokensFromUserRequestDTO, BuyTokensFromUserResponseDTO>(
    async (request) => {
      const { uid } = requireAuthenticatedUser(request);
      return buyFromUserService.buyTokens(uid, request.data);
    },
  ),
);
