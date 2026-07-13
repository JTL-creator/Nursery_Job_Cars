export default function Spinner({ size = 32 }: { size?: number }) {
  return (
    <div
      className="border-4 border-gdm-blue/20 border-t-gdm-lime rounded-full animate-spin"
      style={{ width: size, height: size }}
    />
  );
}
