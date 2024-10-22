import { HttpStatus } from '@nestjs/common';

export type ICadrartLoginDto = {
  mail: string;
  password: string;
};

export type ICadrartIsLoggedInDto = {
  token: string;
};

export type ICadrartConnectedUser = {
  firstName: string;
  id: number;
  image: string;
  lastName: string;
  mail: string;
  name: string;
};

export type ICadrartLoginResponse = {
  statusCode: HttpStatus.OK | HttpStatus.UNAUTHORIZED;
  user?: ICadrartConnectedUser;
};

export type ICadrartIsLoggedInResponse = {
  statusCode: HttpStatus;
  user?: ICadrartConnectedUser;
};

export type ICadrartTokenPayload = {
  sub: number;
  username: string;
};
