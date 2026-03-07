export type ApiErrorResponse = {
  status: number;
  message: string;
  timestamp: string;
  path: string;
};

export type ApiResponse<T> = {
    success: boolean;
    data?: T;
    error?: ApiErrorResponse;
}