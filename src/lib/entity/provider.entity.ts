import { ICadrartArticle } from './article.entity';
import { ICadrartApiEntity } from './base.entity';

export interface ICadrartProvider extends ICadrartApiEntity {
  name: string;
  address?: string;
  vat?: string;
  iban?: string;
  mail?: string;
  articles?: ICadrartArticle[];
}
