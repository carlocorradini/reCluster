import type { Node } from '../types';
import { nodes } from '../../data';

export async function resolveNodeReference(
  ref: Pick<Node, 'id'>
): Promise<Node | undefined> {
  return nodes.find((node) => node.id === ref.id);
}
