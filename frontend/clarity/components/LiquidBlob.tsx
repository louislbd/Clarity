import { BlobCard, BlobCardContent } from "./blob-card";

interface LiquidBlobProps {
    title?: string;
    description?: string;
    height?: string;
    width?: string;
    className?: string;
}

export default function LiquidBlob({
    height = "h-[400px]",
    width = "w-full",
    className = "",
} : LiquidBlobProps) {
    return (
        <BlobCard className={`bg-[var(--background)] ${className}`}>
        <BlobCardContent className="p-0">
            <div className={`${height} ${width} overflow-hidden bg-transparent`}>
                <iframe
                    src="/blob.html"
                    title="Interactive Liquid Blob Visualization"
                    className="w-full h-full border-0"
                    sandbox="allow-scripts"
                    style={{ display: 'block', background: 'transparent' }}
                />
            </div>
        </BlobCardContent>
        </BlobCard>
    );
}
