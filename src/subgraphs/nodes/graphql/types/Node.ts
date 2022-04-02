import { Directive, Field, ObjectType } from 'type-graphql';
import { GraphQLID, GraphQLNonEmptyString } from '~/graphql/scalars';

@ObjectType()
@Directive(`@key(fields: "id")`)
export class Node {
  @Field(() => GraphQLID)
  id!: string;

  @Field(() => GraphQLNonEmptyString)
  name!: string;
}
