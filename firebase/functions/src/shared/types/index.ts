// Autor: Allan Giovanni Matias Paes

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
