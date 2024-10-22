import { ICadrartTag } from './tag.entity';
import { ICadrartOffer } from './offer.entity';
import { ICadrartApiEntity } from './base.entity';

export interface ICadrartClient extends ICadrartApiEntity {
  lastName: string;
  firstName: string;
  company?: string;
  address?: string;
  mail?: string;
  phone?: string;
  phone2?: string;
  vat?: number;
  tag?: ICadrartTag;
  offers?: ICadrartOffer[];
  reduction: number;
}
