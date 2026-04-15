import { db } from "../../shared/firebase";
import { UserCreateDTO, UserProfile } from "../types";

const usersCollection = db.collection("users");

export async function createUserProfile(profile: UserCreateDTO): Promise<void> {
  await usersCollection.doc(profile.uid).set(profile);
}

export async function getUserByEmail(
  email: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("email", "==", email).get();

  if (snapshot.empty) {
    return undefined;
  }

  return snapshot.docs[0].data() as UserProfile;
}

export async function getUserByCpf(
  cpf: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("cpf", "==", cpf).get();

  if (snapshot.empty) {
    return undefined;
  }

  return snapshot.docs[0].data() as UserProfile;
}

export async function getUserByPhone(
  phone: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("phone", "==", phone).get();
  if (snapshot.empty) return undefined;

  return snapshot.docs[0].data() as UserProfile;
}
