
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'shortenTitle'
})
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit = 35): string {
    return value.length > limit ? value.substring(0, limit) + '...' : value;
  }
}