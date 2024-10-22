import { ICadrartApiEntity } from './base.entity';
import { ICadrartOffer } from './offer.entity';

export interface ICadrartTeamMember extends ICadrartApiEntity {
  lastName: string;
  firstName: string;
  address?: string;
  mail?: string;
  phone?: string;
  password: string;
  image: string;
  offers?: ICadrartOffer[];
}
