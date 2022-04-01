import { Arg, Query, Resolver } from 'type-graphql';
import { Node } from '../types';
import { GraphQLID } from '../scalars';

@Resolver(Node)
export class NodeResolver {
  // eslint-disable-next-line class-methods-use-this
  @Query(() => Node, {
    nullable: true,
    description: `Node that matches the id`
  })
  node(@Arg('id', () => GraphQLID) id: string): Promise<Node | undefined> {
    return new Promise((resolve) => {
      resolve({ id, name: 'test' });
    });
  }
}
