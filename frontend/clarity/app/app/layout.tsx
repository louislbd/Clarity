import AppNavbar from "@/components/shared/AppNavbar";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppNavbar />
      <main>{children}</main>
    </>
  );
}
