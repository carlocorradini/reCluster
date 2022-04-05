import { nodes } from '~/data';
import type { Node } from '../types';

export async function resolveNodeReference(
  ref: Pick<Node, 'id'>
): Promise<Node | undefined> {
  return nodes.find((node) => node.id === ref.id);
}
