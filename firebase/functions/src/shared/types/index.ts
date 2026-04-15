export type ApiResponse<T> = {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    status: number;
  };
};

export type FunctionResponse = {
  count: number;
  filters: {
    availableStages: string[];
    stage: string | null;
    search: string | null;
  };
};

export type RecordFunctionResponse<T> = FunctionResponse & {
  data: Record<string, T>;
};

export type SingleFunctionResponse<T> = FunctionResponse & {
  data: T;
};
