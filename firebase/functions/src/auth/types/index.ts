export type UserProfile = {
  uid: string;
  name: string;
  email: string;
  cpf: string;
  walletBalance: number;
  createdAt: Date;
};

export type SignupData = {
  name: string;
  email: string;
  cpf: string;
  password?: string; // OPCIONAL se for login social, mas obrigatorio para email/pass
};

export type SignupResponse = {
  uid: string;
  name: string;
  email: string;
};
