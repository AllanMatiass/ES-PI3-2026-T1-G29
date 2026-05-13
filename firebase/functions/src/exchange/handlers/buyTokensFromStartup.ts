// firebase/functions/src/exchange/handlers/buyTokensFromStartup.ts

import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { BuyFromStartupService } from "../shared/buyFromStartupService";
import {
  BuyTokensFromStartupRequestDTO,
  BuyTokensFromStartupResponseDTO,
} from "../types/dtos";

const buyFromStartupService = new BuyFromStartupService();

export const buyTokensFromStartup = onCall(
  withCallHandler<BuyTokensFromStartupRequestDTO, BuyTokensFromStartupResponseDTO>(
    async (request) => {
      const { uid } = requireAuthenticatedUser(request);
      return buyFromStartupService.buyTokens(uid, request.data);
    },
  ),
);
