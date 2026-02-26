function escapePdfText(input: string) {
  return input.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

export function buildSimpleTextPdf(title: string, lines: string[]) {
  const contentLines = [title, '', ...lines].slice(0, 180);
  let y = 790;
  const chunks: string[] = ['BT', '/F1 12 Tf'];

  for (const line of contentLines) {
    chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText(line)}) Tj`);
    y -= 16;
    if (y < 40) break;
  }
  chunks.push('ET');

  const stream = chunks.join('\n');

  const objects: string[] = [];
  objects.push('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
  objects.push('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');
  objects.push('3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj');
  objects.push('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
  objects.push(`5 0 obj << /Length ${Buffer.byteLength(stream, 'utf8')} >> stream\n${stream}\nendstream endobj`);

  let body = '%PDF-1.4\n';
  const xref: number[] = [0];

  for (const obj of objects) {
    xref.push(Buffer.byteLength(body, 'utf8'));
    body += `${obj}\n`;
  }

  const xrefStart = Buffer.byteLength(body, 'utf8');
  body += `xref\n0 ${objects.length + 1}\n`;
  body += '0000000000 65535 f \n';
  for (let i = 1; i < xref.length; i += 1) {
    body += `${String(xref[i]).padStart(10, '0')} 00000 n \n`;
  }
  body += `trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`;

  return Buffer.from(body, 'utf8');
}
