import { ICadrartArticle } from './article.entity';
import { ICadrartApiEntity } from './base.entity';

export interface ICadrartStock extends ICadrartApiEntity {
  createdAt: Date;
  articleName?: string;
  article?: ICadrartArticle;
  orderDate?: Date;
  deliveryDate?: Date;
}
