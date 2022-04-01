import { Field, ObjectType } from 'type-graphql';
import { GraphQLID, GraphQLNonEmptyString } from '../scalars';

@ObjectType()
export class Node {
  @Field(() => GraphQLID)
  id!: string;

  @Field(() => GraphQLNonEmptyString)
  name!: string;
}
