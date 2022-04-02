import { Arg, Query, Resolver } from 'type-graphql';
import { GraphQLID } from '~/graphql/scalars';
import { Node } from '../types';
import { nodes } from '../../data';

@Resolver(Node)
export class NodeResolver {
  // eslint-disable-next-line class-methods-use-this
  @Query(() => Node, { nullable: true })
  async node(
    @Arg('id', () => GraphQLID) id: string
  ): Promise<Node | undefined> {
    return nodes.find((node) => node.id === id);
  }

  // eslint-disable-next-line class-methods-use-this
  @Query(() => [Node])
  async nodes(): Promise<Node[]> {
    return nodes;
  }
}
